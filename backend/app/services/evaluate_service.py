from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models import Order, OrderDetail, ProductDetail, Evaluate, EvaluateImage
from app.models.order import OrderStatus
from app.models.user import User, UserRole


class EvaluateService:
    @staticmethod
    def _mask_username(username: Optional[str]) -> Optional[str]:
        name = (username or "").strip()
        if not name:
            return None
        if len(name) <= 2:
            return f"{name[0]}*" if len(name) == 2 else "*"
        return f"{name[:1]}{'*' * max(3, len(name) - 2)}{name[-1:]}"

    @staticmethod
    def _matched_variants_for_product(evaluate: Evaluate, product_id: int) -> List[str]:
        order = getattr(evaluate, "order", None)
        if not order or not getattr(order, "order_details", None):
            return []

        variants: List[str] = []
        for detail in order.order_details:
            product_detail = getattr(detail, "product_detail", None)
            if not product_detail or product_detail.product_id != product_id:
                continue

            color_name = getattr(getattr(product_detail, "color", None), "name", None)
            size_name = getattr(getattr(product_detail, "size", None), "size", None)
            parts = []
            if color_name:
                parts.append(f"Màu: {color_name}")  
            if size_name:
                parts.append(f"Kích thước: {size_name}")
            label = ", ".join(parts) if parts else f"Biến thể #{product_detail.id}"
            if label not in variants:
                variants.append(label)

        return variants

    @staticmethod
    def _build_product_summary_text(
        total_evaluates: int,
        average_rate: float,
        rate_count_map: dict,
        sample_contents: List[str],
    ) -> Optional[str]:
        if total_evaluates <= 0:
            return None

        top_star = None
        top_count = -1
        for star in range(5, 0, -1):
            count = int(rate_count_map.get(star, 0))
            if count > top_count:
                top_star = star
                top_count = count

        parts = [
            f"Có {total_evaluates} đánh giá, trung bình {average_rate:.1f}/5 sao."
        ]
        if top_star and top_count > 0:
            parts.append(f"Mức {top_star} sao xuất hiện nhiều nhất ({top_count} đánh giá).")
        if sample_contents:
            snippet = sample_contents[0].strip().replace("\n", " ")
            if len(snippet) > 160:
                snippet = f"{snippet[:157].rstrip()}..."
            parts.append(f"Nhận xét nổi bật: {snippet}")
        return " ".join(parts)

    @staticmethod
    def _product_evaluate_subquery(db: Session, product_id: int):
        return (
            db.query(
                Evaluate.id.label("evaluate_id"),
                func.max(Evaluate.rate).label("rate"),
                func.max(Evaluate.content).label("content"),
                func.max(Evaluate.created_at).label("created_at"),
            )
            .join(Order, Order.id == Evaluate.order_id)
            .join(OrderDetail, OrderDetail.order_id == Order.id)
            .join(ProductDetail, ProductDetail.id == OrderDetail.product_detail_id)
            .filter(ProductDetail.product_id == product_id)
            .group_by(Evaluate.id)
            .subquery()
        )

    @staticmethod
    def create_evaluation(
        db: Session,
        user_id: int,
        order_id: int,
        rate: int,
        content: Optional[str],
        image_urls: List[str],
    ):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        if order.status != OrderStatus.COMPLETED:
            raise HTTPException(status_code=400, detail="Chỉ có thể đánh giá đơn hàng đã hoàn thành")

        existing_eval = db.query(Evaluate).filter(Evaluate.order_id == order_id).first()
        if existing_eval:
            raise HTTPException(status_code=400, detail="Bạn đã đánh giá đơn hàng này rồi")

        new_eval = Evaluate(
            order_id=order_id,
            user_id=user_id,
            rate=rate,
            content=content,
            # giữ tương thích cột cũ vì chưa xóa
            image=image_urls[0] if image_urls else None,
        )
        db.add(new_eval)
        db.flush() 

        for idx, url in enumerate(image_urls):
            db.add(
                EvaluateImage(
                    evaluate_id=new_eval.id,
                    image_url=url,
                    sort_order=idx,
                )
            )

        db.commit()

        evaluate = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == new_eval.id)
            .first()
        )
        return evaluate

    @staticmethod
    def reply_evaluation(
        db: Session,
        evaluate_id: int,
        admin_id: int,
        admin_reply: str,
    ):
        reply_text = (admin_reply or "").strip()
        if not reply_text:
            raise HTTPException(status_code=400, detail="Nội dung phản hồi không được để trống")

        evaluate = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == evaluate_id)
            .first()
        )
        if not evaluate:
            raise HTTPException(status_code=404, detail="Đánh giá không tồn tại")

        evaluate.admin_id = admin_id
        evaluate.admin_reply = reply_text
        evaluate.admin_replied_at = datetime.now()

        db.commit()
        db.refresh(evaluate)
        return evaluate


    @staticmethod
    def get_admin_evaluations(
        db: Session,
        page: int = 1,
        per_page: int = 8,
        has_reply: Optional[bool] = None,
        order_id: Optional[int] = None,
    ):
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        query = db.query(Evaluate)

        if order_id is not None:
            query = query.filter(Evaluate.order_id == order_id)

        if has_reply is True:
            query = query.filter(Evaluate.admin_reply.isnot(None))
        elif has_reply is False:
            query = query.filter(Evaluate.admin_reply.is_(None))

        total = query.count()

        items = (
            query.options(joinedload(Evaluate.images))
            .order_by(Evaluate.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )

        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "items": items,
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": total_pages,
            },
        }


    @staticmethod
    def get_my_evaluations(
        db: Session,
        user_id: int,
        page: int = 1,
        per_page: int = 8,
    ):
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        query = db.query(Evaluate).filter(Evaluate.user_id == user_id)

        total = query.count()

        items = (
            query.options(joinedload(Evaluate.images))
            .order_by(Evaluate.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )

        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "items": items,
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": total_pages,
            },
        }
    
    @staticmethod
    def get_product_evaluations(
        db: Session,
        product_id: int,
        page: int = 1,
        per_page: int = 8,
    ):
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        evaluate_sq = EvaluateService._product_evaluate_subquery(db=db, product_id=product_id)

        total = db.query(func.count()).select_from(evaluate_sq).scalar() or 0

        avg_rate = db.query(func.avg(evaluate_sq.c.rate)).select_from(evaluate_sq).scalar() or 0

        rate_rows = (
            db.query(evaluate_sq.c.rate, func.count())
            .select_from(evaluate_sq)
            .group_by(evaluate_sq.c.rate)
            .all()
        )
        rate_count_map = {int(rate): int(count) for rate, count in rate_rows if rate is not None}

        total_with_images = (
            db.query(func.count(func.distinct(evaluate_sq.c.evaluate_id)))
            .select_from(evaluate_sq)
            .join(EvaluateImage, EvaluateImage.evaluate_id == evaluate_sq.c.evaluate_id)
            .scalar()
            or 0
        )

        sample_content_rows = (
            db.query(evaluate_sq.c.content)
            .select_from(evaluate_sq)
            .filter(evaluate_sq.c.content.isnot(None))
            .order_by(evaluate_sq.c.created_at.desc(), evaluate_sq.c.evaluate_id.desc())
            .limit(5)
            .all()
        )
        sample_contents = [str(row[0]).strip() for row in sample_content_rows if str(row[0]).strip()]

        evaluate_id_rows = (
            db.query(evaluate_sq.c.evaluate_id)
            .select_from(evaluate_sq)
            .order_by(evaluate_sq.c.created_at.desc(), evaluate_sq.c.evaluate_id.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )
        evaluate_ids = [int(row[0]) for row in evaluate_id_rows]

        items = []
        if evaluate_ids:
            evaluates = (
                db.query(Evaluate)
                .options(
                    joinedload(Evaluate.images),
                    joinedload(Evaluate.user),
                    joinedload(Evaluate.order)
                    .joinedload(Order.order_details)
                    .joinedload(OrderDetail.product_detail)
                    .joinedload(ProductDetail.color),
                    joinedload(Evaluate.order)
                    .joinedload(Order.order_details)
                    .joinedload(OrderDetail.product_detail)
                    .joinedload(ProductDetail.size),
                )
                .filter(Evaluate.id.in_(evaluate_ids))
                .all()
            )

            evaluate_map = {evaluate.id: evaluate for evaluate in evaluates}
            ordered_evaluates = [evaluate_map[evaluate_id] for evaluate_id in evaluate_ids if evaluate_id in evaluate_map]

            for evaluate in ordered_evaluates:
                evaluater_name = getattr(getattr(evaluate, "user", None), "username", None)
                items.append(
                    {
                        "id": evaluate.id,
                        "order_id": evaluate.order_id,
                        "user_id": evaluate.user_id,
                        "admin_id": evaluate.admin_id,
                        "rate": evaluate.rate,
                        "content": evaluate.content,
                        "admin_reply": evaluate.admin_reply,
                        "admin_replied_at": evaluate.admin_replied_at,
                        "created_at": evaluate.created_at,
                        "updated_at": evaluate.updated_at,
                        "images": list(getattr(evaluate, "images", []) or []),
                        "evaluater_name": evaluater_name,
                        "evaluater_name_masked": EvaluateService._mask_username(evaluater_name),
                        "matched_variants": EvaluateService._matched_variants_for_product(evaluate, product_id),
                        "has_images": bool(getattr(evaluate, "images", None)),
                    }
                )

        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "summary": {
                "product_id": product_id,
                "average_rate": round(float(avg_rate or 0), 1),
                "total_evaluates": total,
                "total_with_images": total_with_images,
                "summary_text": EvaluateService._build_product_summary_text(
                    total_evaluates=total,
                    average_rate=float(avg_rate or 0),
                    rate_count_map=rate_count_map,
                    sample_contents=sample_contents,
                ),
                "rate_counts": [
                    {"star": star, "count": int(rate_count_map.get(star, 0))}
                    for star in range(5, 0, -1)
                ],
            },
            "items": items,
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": total_pages,
            },
        }
    
    @staticmethod
    def get_evaluation_by_id(
        db: Session,
        evaluate_id: int,
        current_user: User,
    ):
        query = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == evaluate_id)
        )

        if current_user.role != UserRole.ADMIN:
            query = query.filter(Evaluate.user_id == current_user.id)
        
        evaluate = query.first()
        if not evaluate:
            raise HTTPException(status_code=404, detail="Đánh giá không tồn tại")
        
        return evaluate

    @staticmethod
    def get_evaluation_by_order(
        db: Session,
        order_id: int,
        current_user: User,
    ):
        query = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.order_id == order_id)
        )

        if current_user.role != UserRole.ADMIN:
            query = query.filter(Evaluate.user_id == current_user.id)

        evaluate = query.first()
        if not evaluate:
            raise HTTPException(status_code=404, detail="Đánh giá không tồn tại")

        return evaluate
