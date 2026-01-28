from datetime import date, datetime
from typing import List, Optional

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.deps import require_admin
from app.api.utils import format_dashboard_meta, get_status_tag, get_status_tone
from app.db.session import get_db
from app.models import Order, OrderDetail, Product, Receipt, User
from app.models.order import OrderStatus
from app.models.receipt import ReceiptStatus
from app.schemas.dashboard import DashboardActivityItemOut, DashboardSummaryOut

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary", response_model=DashboardSummaryOut)
def get_summary(
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    today = date.today()

    orders_today = (
        db.query(func.count(Order.id))
        .filter(func.date(Order.created_at) == today)
        .scalar()
        or 0
    )

    revenue_today = (
        db.query(func.coalesce(func.sum(OrderDetail.price * OrderDetail.quantity), 0))
        .join(Order, Order.id == OrderDetail.order_id)
        .filter(
            func.date(Order.created_at) == today,
            Order.status != OrderStatus.CANCELLED,
        )
        .scalar()
        or 0
    )

    total_users = db.query(func.count(User.id)).scalar() or 0
    total_products = db.query(func.count(Product.id)).scalar() or 0

    return {
        "orders_today": int(orders_today),
        "revenue_today": float(revenue_today),
        "total_users": int(total_users),
        "total_products": int(total_products),
    }


@router.get("/activity", response_model=List[DashboardActivityItemOut])
def get_activity(
    limit: int = 6,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    if limit < 1:
        limit = 1
    if limit > 20:
        limit = 20

    orders = (
        db.query(Order)
        .order_by(Order.created_at.desc())
        .limit(limit)
        .all()
    )
    receipts = (
        db.query(Receipt)
        .order_by(Receipt.created_at.desc())
        .limit(limit)
        .all()
    )

    items = []
    for order in orders:
        items.append(
            {
                "created_at": order.created_at,
                "title": f"Đơn hàng #{order.id}",
                "tag": get_status_tag(order.status),
                "tone": get_status_tone(order.status),
            }
        )

    for receipt in receipts:
        items.append(
            {
                "created_at": receipt.created_at,
                "title": f"Phiếu nhập #{receipt.id}",
                "tag": get_status_tag(receipt.status),
                "tone": get_status_tone(receipt.status),
            }
        )

    items.sort(
        key=lambda item: item.get("created_at") or datetime.min,
        reverse=True,
    )

    output = []
    for item in items[:limit]:
        output.append(
            {
                "title": item["title"],
                "meta": format_dashboard_meta(item.get("created_at")),
                "tag": item["tag"],
                "tone": item["tone"],
            }
        )

    return output
