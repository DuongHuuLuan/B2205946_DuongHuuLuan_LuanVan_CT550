from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.models import *
from app.schemas import *
from app.schemas.order import OrderStatusUpdate
from app.services.order_service import OrderService
from app.api.deps import require_user, require_admin


router = APIRouter(prefix="/orders", tags=["Order"])

@router.post("/", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    order_in: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """API thực hiện đặt hàng từ giỏ hàng của người dùng"""
    return OrderService.create_order(db=db,user_id=current_user.id,order_in=order_in)

@router.get("/history", response_model=List[OrderOut])
def get_orders(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """Lấy danh sách tất cả đơn hàng đã mua của người dùng hiện tại"""
    orders = OrderService.get_orders(db=db, user_id=current_user.id)
    # return [OrderDetailOut.from_orm(o) for o in orders]
    return orders

@router.get("/{order_id}", response_model=OrderOut)
def get_order_details(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Xem chi tiết một đơn hàng cụ thể bằng ID.
    """
    return OrderService.get_order_byID(db=db, order_id=order_id, user_id=current_user.id)

# --- ENDPOINT 4: HỦY ĐƠN HÀNG ---
@router.post("/{order_id}/cancel")
def cancel_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Hủy đơn hàng (chỉ áp dụng khi đơn ở trạng thái PENDING).
    """
    return OrderService.delete_order(db=db, order_id=order_id, user_id=current_user.id)

@router.put("/{order_id}/status", response_model=OrderOut)
def update_status(
    order_id: int,
    status_data: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """
    Cập nhật trạng thái đơn hàng (ADMIN)
    các trạng thái pending, shipping,completed, cancelled
    """
    return OrderService.update_status(
        db=db, order_id=order_id, status=status_data.status
    )

@router.post("/{order_id}/confirm-delivery", response_model=OrderOut)
def confirm_delivery(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Người dùng xác nhận đã nhận hàng thành công
    """
    return OrderService.confirm_delivery(
        db=db,
        order_id=order_id,
        user_id=current_user.id
    )