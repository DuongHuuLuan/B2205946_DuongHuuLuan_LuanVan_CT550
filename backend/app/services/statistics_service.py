from datetime import date, datetime, time, timedelta
from decimal import Decimal
from typing import Dict, List, Tuple

from sqlalchemy import func, or_
from sqlalchemy.orm import Query, Session

from app.models import (
    Category,
    Evaluate,
    Order,
    OrderDetail,
    PaymentMethod,
    Product,
    ProductDetail,
)
from app.models.order import OrderStatus
from app.schemas.statistics import (
    StatisticsFilterParams,
    StatisticsOrderStatus,
    StatisticsRange,
    StatisticsScope,
)


STATUS_LABELS = {
    OrderStatus.PENDING.value: "Chờ xác nhận",
    OrderStatus.SHIPPING.value: "Đang giao",
    OrderStatus.COMPLETED.value: "Hoàn tất",
    OrderStatus.CANCELLED.value: "Đã hủy",
}


class StatisticsService:
    @staticmethod
    def get_overview(db: Session, filters: StatisticsFilterParams) -> dict:
        total_orders = int(
            StatisticsService._apply_order_filters(
                db.query(func.count(Order.id)),
                filters,
            ).scalar()
            or 0
        )

        revenue = StatisticsService._to_float(
            StatisticsService._apply_order_filters(
                db.query(func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0))
                .join(Order, Order.id == OrderDetail.order_id),
                filters,
                exclude_cancelled_when_all=True,
            ).scalar()
        )

        valid_orders = int(
            StatisticsService._apply_order_filters(
                db.query(func.count(func.distinct(Order.id))),
                filters,
                exclude_cancelled_when_all=True,
            ).scalar()
            or 0
        )

        if filters.order_status == StatisticsOrderStatus.ALL:
            completed_orders = int(
                StatisticsService._apply_date_range(
                    db.query(func.count(Order.id)).filter(Order.status == OrderStatus.COMPLETED),
                    Order.created_at,
                    filters,
                ).scalar()
                or 0
            )
            completion_rate = round((completed_orders / total_orders) * 100) if total_orders else 0
        else:
            completion_rate = 100 if filters.order_status == StatisticsOrderStatus.COMPLETED and total_orders else 0

        return {
            "revenue": revenue,
            "orders": total_orders,
            "average_order_value": round(revenue / valid_orders, 2) if valid_orders else 0,
            "completion_rate": completion_rate,
            "pending_orders": StatisticsService._count_orders_by_status(
                db,
                OrderStatus.PENDING,
                filters,
            ),
            "pending_reviews": StatisticsService._get_pending_reviews_count(db, filters),
        }

    @staticmethod
    def get_revenue_series(db: Session, filters: StatisticsFilterParams) -> dict:
        start_at, end_at = StatisticsService._resolve_date_range(filters.range)

        rows = (
            StatisticsService._apply_order_filters(
                db.query(
                    func.date(Order.created_at).label("bucket_date"),
                    func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0).label("revenue"),
                )
                .join(Order, Order.id == OrderDetail.order_id),
                filters,
                exclude_cancelled_when_all=True,
            )
            .group_by(func.date(Order.created_at))
            .order_by(func.date(Order.created_at))
            .all()
        )

        daily_map: Dict[date, float] = {
            StatisticsService._to_date(row.bucket_date): StatisticsService._to_float(row.revenue)
            for row in rows
        }

        return {"items": StatisticsService._build_revenue_points(filters.range, start_at, end_at, daily_map)}

    @staticmethod
    def get_order_mix(db: Session, filters: StatisticsFilterParams) -> dict:
        rows = (
            StatisticsService._apply_order_filters(
                db.query(
                    Order.status.label("status"),
                    func.count(Order.id).label("count"),
                ),
                filters,
            )
            .group_by(Order.status)
            .all()
        )

        total = sum(int(row.count or 0) for row in rows) or 1
        items = []
        for row in rows:
            status_value = row.status.value if hasattr(row.status, "value") else str(row.status)
            count = int(row.count or 0)
            items.append(
                {
                    "status": status_value,
                    "label": STATUS_LABELS.get(status_value, status_value),
                    "count": count,
                    "share": round((count / total) * 100),
                }
            )

        return {"items": items}

    @staticmethod
    def get_top_products(db: Session, filters: StatisticsFilterParams) -> dict:
        rows = (
            StatisticsService._apply_order_filters(
                db.query(
                    Product.name.label("name"),
                    func.coalesce(Category.name, "-").label("category"),
                    func.coalesce(func.sum(OrderDetail.quantity), 0).label("sold"),
                    func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0).label("revenue"),
                )
                .join(Order, Order.id == OrderDetail.order_id)
                .join(ProductDetail, ProductDetail.id == OrderDetail.product_detail_id)
                .join(Product, Product.id == ProductDetail.product_id)
                .outerjoin(Category, Category.id == Product.category_id),
                filters,
                exclude_cancelled_when_all=True,
            )
            .group_by(Product.id, Product.name, Category.name)
            .order_by(func.sum(OrderDetail.quantity).desc(), func.sum(OrderDetail.price * OrderDetail.quantity).desc())
            .limit(5)
            .all()
        )

        items = []
        for row in rows:
            items.append(
                {
                    "name": row.name,
                    "category": row.category or "-",
                    "sold": int(row.sold or 0),
                    "revenue": StatisticsService._to_float(row.revenue),
                    "note": "",
                }
            )

        return {"items": items}

    @staticmethod
    def get_payment_mix(db: Session, filters: StatisticsFilterParams) -> dict:
        revenue_expr = func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0)

        rows = (
            StatisticsService._apply_order_filters(
                db.query(
                    func.coalesce(PaymentMethod.name, "Chưa chọn").label("method_name"),
                    func.count(func.distinct(Order.id)).label("count"),
                    revenue_expr.label("revenue"),
                )
                .select_from(Order)
                .outerjoin(PaymentMethod, PaymentMethod.id == Order.payment_method_id)
                .outerjoin(OrderDetail, OrderDetail.order_id == Order.id),
                filters,
                exclude_cancelled_when_all=True,
            )
            .group_by(PaymentMethod.id, PaymentMethod.name)
            .order_by(func.count(func.distinct(Order.id)).desc(), revenue_expr.desc())
            .all()
        )

        total_orders = sum(int(row.count or 0) for row in rows) or 1
        items = []
        for row in rows:
            label = row.method_name or "Chưa chọn"
            count = int(row.count or 0)
            items.append(
                {
                    "method": StatisticsService._to_key(label),
                    "label": label,
                    "count": count,
                    "revenue": StatisticsService._to_float(row.revenue),
                    "share": round((count / total_orders) * 100),
                }
            )

        return {"items": items}

    @staticmethod
    def get_reviews_summary(db: Session, filters: StatisticsFilterParams) -> dict:
        summary = StatisticsService._apply_review_filters(
            db.query(
                func.count(Evaluate.id).label("total_reviews"),
                func.coalesce(func.avg(Evaluate.rate), 0).label("average_rating"),
            ),
            filters,
        ).first()

        distribution_rows = (
            StatisticsService._apply_review_filters(
                db.query(
                    Evaluate.rate.label("rate"),
                    func.count(Evaluate.id).label("count"),
                ),
                filters,
            )
            .group_by(Evaluate.rate)
            .all()
        )

        total_reviews = int(summary.total_reviews or 0) if summary else 0
        rate_map = {
            int(row.rate or 0): int(row.count or 0)
            for row in distribution_rows
            if row.rate is not None
        }

        items = []
        for rate in range(5, 0, -1):
            count = rate_map.get(rate, 0)
            items.append(
                {
                    "rate": rate,
                    "count": count,
                    "share": round((count / total_reviews) * 100) if total_reviews else 0,
                }
            )

        return {
            "total_reviews": total_reviews,
            "average_rating": round(StatisticsService._to_float(summary.average_rating), 1) if summary else 0.0,
            "pending_replies": StatisticsService._get_pending_reviews_count(db, filters),
            "items": items,
        }

    @staticmethod
    def get_alerts(db: Session, filters: StatisticsFilterParams) -> dict:
        pending_reviews = StatisticsService._get_pending_reviews_count(db, filters)
        items = []
        include_review_alerts = filters.scope in (StatisticsScope.OVERVIEW, StatisticsScope.REVIEWS)
        include_order_alerts = filters.scope in (StatisticsScope.OVERVIEW, StatisticsScope.SALES)

        if pending_reviews and include_review_alerts:
            items.append(
                {
                    "title": f"{pending_reviews} đánh giá chưa phản hồi",
                    "text": "Nên xử lý sớm để tránh tồn động chăm sóc khách hàng.",
                    "action": "Đánh giá",
                    "to": "/evaluates"
                }
            )

        if include_order_alerts and filters.order_status == StatisticsOrderStatus.ALL:
            pending_orders = StatisticsService._count_orders_by_status(
                db,
                OrderStatus.PENDING,
                filters,
            )
            cancelled_orders = StatisticsService._count_orders_by_status(
                db,
                OrderStatus.CANCELLED,
                filters,
            )

            if pending_orders:
                items.append(
                    {
                        "title": f"{pending_orders} đơn đang chờ xác nhận",
                        "text": "Nhóm đơn này ảnh hưởng trực tiếp đến tốc độ xử lý và giao hàng.",
                        "action": "Đơn hàng",
                        "to": "/orders"
                    }
                )

            if cancelled_orders:
                items.append(
                    {
                        "title": f"{cancelled_orders} đơn đã hủy cần theo dõi",
                        "text": "Nên kiểm tra nguyên nhân hủy để giảm tỉ lệ mất đơn.",
                        "action": "Đơn hàng",
                        "to": "/orders"
                    }
                )
        elif include_order_alerts:
            selected_status = OrderStatus(filters.order_status.value)
            selected_orders = StatisticsService._count_orders_by_status(
                db,
                selected_status,
                filters,
            )
            if selected_orders:
                items.append(
                    {
                        "title": f"{selected_orders} đơn ở trạng thái {STATUS_LABELS.get(selected_status.value, selected_status.value)}",
                        "text": "Đây là nhóm đơn hàng được lọc hiện tại để ưu tiên theo dõi.",
                        "action": "Đơn hàng",
                        "to": "/orders",
                    }
                )

        return {"items": items}

    @staticmethod
    def _count_orders_by_status(
        db: Session,
        status: OrderStatus,
        filters: StatisticsFilterParams,
    ) -> int:
        return int(
            StatisticsService._apply_date_range(
                db.query(func.count(Order.id)).filter(Order.status == status),
                Order.created_at,
                filters,
            ).scalar()
            or 0
        )

    @staticmethod
    def _apply_order_filters(
        query: Query,
        filters: StatisticsFilterParams,
        exclude_cancelled_when_all: bool = False,
    ) -> Query:
        query = StatisticsService._apply_date_range(query, Order.created_at, filters)

        if filters.order_status != StatisticsOrderStatus.ALL:
            query = query.filter(Order.status == OrderStatus(filters.order_status.value))
        elif exclude_cancelled_when_all:
            query = query.filter(Order.status != OrderStatus.CANCELLED)

        return query

    @staticmethod
    def _apply_review_filters(query: Query, filters: StatisticsFilterParams) -> Query:
        query = StatisticsService._apply_date_range(query, Evaluate.created_at, filters)

        if filters.order_status != StatisticsOrderStatus.ALL:
            query = query.join(Order, Order.id == Evaluate.order_id).filter(
                Order.status == OrderStatus(filters.order_status.value)
            )

        return query

    @staticmethod
    def _apply_date_range(query: Query, column, filters: StatisticsFilterParams) -> Query:
        start_at, end_at = StatisticsService._resolve_date_range(filters.range)
        return query.filter(column >= start_at, column < end_at)

    @staticmethod
    def _resolve_date_range(range_key: StatisticsRange) -> Tuple[datetime, datetime]:
        today = date.today()
        tomorrow = today + timedelta(days=1)
        end_at = datetime.combine(tomorrow, time.min)

        if range_key == StatisticsRange.LAST_7_DAYS:
            start_date = today - timedelta(days=6)
        elif range_key == StatisticsRange.LAST_30_DAYS:
            start_date = today - timedelta(days=29)
        elif range_key == StatisticsRange.MONTH:
            start_date = today.replace(day=1)
        else:
            quarter_start_month = ((today.month - 1) // 3) * 3 + 1
            start_date = date(today.year, quarter_start_month, 1)

        return datetime.combine(start_date, time.min), end_at

    @staticmethod
    def _build_revenue_points(
        range_key: StatisticsRange,
        start_at: datetime,
        end_at: datetime,
        daily_map: Dict[date, float],
    ) -> List[dict]:
        if range_key == StatisticsRange.LAST_7_DAYS:
            return StatisticsService._build_daily_points(start_at.date(), end_at.date(), daily_map)
        if range_key == StatisticsRange.LAST_30_DAYS:
            return StatisticsService._build_window_points(start_at.date(), end_at.date(), daily_map, 5)
        if range_key == StatisticsRange.MONTH:
            return StatisticsService._build_window_points(start_at.date(), end_at.date(), daily_map, 7)
        return StatisticsService._build_month_points(start_at.date(), end_at.date(), daily_map)

    @staticmethod
    def _build_daily_points(start_date: date, end_date: date, daily_map: Dict[date, float]) -> List[dict]:
        items = []
        current = start_date
        while current < end_date:
            items.append(
                {
                    "label": current.strftime("%d/%m"),
                    "value": daily_map.get(current, 0),
                }
            )
            current += timedelta(days=1)
        return items

    @staticmethod
    def _build_window_points(
        start_date: date,
        end_date: date,
        daily_map: Dict[date, float],
        window_days: int,
    ) -> List[dict]:
        items = []
        current = start_date
        while current < end_date:
            window_end = min(current + timedelta(days=window_days), end_date)
            total = 0.0
            day_cursor = current
            while day_cursor < window_end:
                total += daily_map.get(day_cursor, 0)
                day_cursor += timedelta(days=1)

            label_end = window_end - timedelta(days=1)
            items.append(
                {
                    "label": f"{current.strftime('%d/%m')}-{label_end.strftime('%d/%m')}",
                    "value": round(total, 2),
                }
            )
            current = window_end
        return items

    @staticmethod
    def _build_month_points(start_date: date, end_date: date, daily_map: Dict[date, float]) -> List[dict]:
        items = []
        current = start_date
        while current < end_date:
            if current.month == 12:
                next_month = date(current.year + 1, 1, 1)
            else:
                next_month = date(current.year, current.month + 1, 1)

            bucket_end = min(next_month, end_date)
            total = 0.0
            day_cursor = current
            while day_cursor < bucket_end:
                total += daily_map.get(day_cursor, 0)
                day_cursor += timedelta(days=1)

            items.append(
                {
                    "label": current.strftime("%m/%Y"),
                    "value": round(total, 2),
                }
            )
            current = bucket_end
        return items

    @staticmethod
    def _get_pending_reviews_count(db: Session, filters: StatisticsFilterParams) -> int:
        query = StatisticsService._apply_review_filters(
            db.query(func.count(Evaluate.id)).filter(
                or_(Evaluate.admin_reply.is_(None), func.trim(Evaluate.admin_reply) == "")
            ),
            filters,
        )
        return int(query.scalar() or 0)

    @staticmethod
    def _to_float(value) -> float:
        if value is None:
            return 0.0
        if isinstance(value, Decimal):
            return float(value)
        return float(value)

    @staticmethod
    def _to_date(value) -> date:
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        return datetime.fromisoformat(str(value)).date()

    @staticmethod
    def _to_key(value: str) -> str:
        return "_".join(str(value or "").strip().lower().split()) or "unknown"
