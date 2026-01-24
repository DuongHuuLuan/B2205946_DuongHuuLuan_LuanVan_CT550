from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Dict, Optional
from app.db.session import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.services.discount_service import DiscountService
from app.schemas.discount import (
    DiscountCreate,
    DiscountUpdate,
    DiscountOut,
    DiscountPaginationOut,
)

router = APIRouter(prefix="/discounts", tags=["Discount"])


@router.get("/discount-cart", response_model=List[DiscountOut])
def get_discount_by_cart(
    category_ids: List[int] = Query(...),
    db: Session = Depends(get_db)
):
    """
    Lay danh sach cac ma giam gia goi y dua tren cac san pham trong gio hang.
    Frontend se lay category_id tu cac item trong gio gui len.
    """
    discounts = DiscountService.get_available_discouts_for_cart(db, category_ids=category_ids)
    return discounts


@router.get("/check/{code_name}", response_model=DiscountOut)
def check_discount_code(code_name: str, db: Session = Depends(get_db)):
    """Kiem tra ma giam gia co hop le va con han khong."""
    discount = DiscountService.get_valid_discount(db, code_name=code_name)
    if not discount:
        raise HTTPException(
            status_code=404,
            detail="Ma giam gia khong ton tai, da het han hoac chua den thoi gian ap dung",
        )
    return discount


@router.get("/by-categories", response_model=Dict[int, DiscountOut])
def get_discounts_by_categories(
    category_ids: List[int] = Query(...),
    db: Session = Depends(get_db)
):
    """Lay danh sach giam gia dang ap dung cho nhieu danh muc."""
    return DiscountService.get_valid_discounts_by_category_ids(db, category_ids)


# --- Admin ---

@router.get("/", response_model=DiscountPaginationOut)
def get_all_discounts(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API lấy tất cả mã giảm giá"""
    return DiscountService.get_all(db, page=page, per_page=per_page, keyword=q)


@router.get("/{discount_id}", response_model=DiscountOut)
def get_discount_id(
    discount_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API lấy mã giảm giá theo ID"""
    return DiscountService.get_id(db, discount_id)


@router.post("/", response_model=DiscountOut, status_code=status.HTTP_201_CREATED)
def create_discount(
    discount_in: DiscountCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API Tạo một mã giảm giá mới"""
    return DiscountService.create(db, discount_in)


@router.put("/{discount_id}", response_model=DiscountOut)
def update_discount(
    discount_id: int,
    discount_in: DiscountUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API chỉnh sửa mã giảm giá"""
    return DiscountService.update(db, discount_id, discount_in)


@router.delete("/{discount_id}", status_code=status.HTTP_200_OK)
def delete_discount(
    discount_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API xóa mọt mã giảm giá"""
    return DiscountService.delete(db, discount_id)
