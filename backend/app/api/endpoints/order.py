from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.models import *
from app.schemas import *
from app.services.order_service import OrderService
from app.api.deps import require_user


router = APIRouter(prefix="/orders", tags=["Order"])

@router.post("/", response_model=OrderOut)
def create_order(
    order_in: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """API thực hiện đặt hàng từ giỏ hàng của người dùng"""
    return OrderService.create_order(db=db,user_id=current_user.id,order_in=order_in)

