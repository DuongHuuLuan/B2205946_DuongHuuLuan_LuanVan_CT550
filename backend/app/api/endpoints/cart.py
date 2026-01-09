from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.models import *
from app.schemas import *
from app.services.cart_service import CartService
from app.api.deps import require_user


router = APIRouter(prefix="/carts", tags=["Cart"])

@router.get("/", response_model= CartOut)
def get_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Lấy toàn bộ thông tin giỏ hàng của người dùng hiện tại
    Tính toán tổng tiền dựa trên giá của từng biến thể
    """
    return CartService.get_cart(db, user_id=current_user.id)


@router.post("/cart-details", response_model= CartOut)
def add_to_cart(
    cart_detail_in: CartDetailCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Thêm một biến thể sản phẩm vào giỏ hàng.
    Nếu sản phẩm đã tồn tại, cộng dồn số lượng
    """
    return CartService.add_to_cart(db,user_id=current_user.id,cart_detail_in=cart_detail_in)

@router.put("/cart-details/{cart_detail_id}", response_model=CartOut)
def update_cart(
    cart_detail_id: int,
    new_quantity: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Cập nhật số lượng sản phẩm trong giỏ
    """
    if new_quantity <=0:
        raise HTTPException(status_code=400, detail="Số lượng phải lớn hơn 0")
    return CartService.update_cart_detail(db, user_id=current_user.id, cart_detail_id=cart_detail_id, new_quantity=new_quantity)

@router.delete("/cart-details/{cart_detail_id}")
def delete_cart(
    cart_detail_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """ API xóa một mục hàng cụ thể khỏi giỏ dựa trên id của CartDetail"""
    return CartService.delete_cart_detail(db,user_id=current_user.id,cart_detail_id=cart_detail_id)


@router.get("/test", response_model= List[ImageUrlOut])
def test_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Test lấy giỏ hàng từ quan hệ
    """
    return CartService.get_cart2(db, user_id=current_user.id)