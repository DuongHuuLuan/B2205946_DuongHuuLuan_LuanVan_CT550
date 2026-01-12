from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Dict
from app.db.session import get_db
from app.services.discount_service import DiscountService
from app.schemas.discount import DiscountBase, DiscountOut
from app.models.discount import Discount

router = APIRouter(prefix="/discounts",tags=["Discount"])


@router.get("/discount-cart", response_model=List[DiscountOut])
def get_discount_by_cart(
    category_ids: List[int] = Query(...),
    db: Session = Depends(get_db)
):
    """
    Lấy danh sách các mã giảm giá gợi ý dựa trên các sản phẩm trong giỏ hàng.
    Frontend sẽ lấy category_id từ các itme trong giỏ gửi lên
    """

    discounts = DiscountService.get_available_discouts_for_cart(db, category_ids=category_ids)
    # return list(discounts.values())
    return discounts

@router.get("/check/{code_name}", response_model=DiscountOut)
def check_discount_code(code_name: str, db: Session = Depends(get_db)):
    """
    Kiểm tra một mã giảm giá cụ thể xem có hợp lệ và còn hạn không.
    """
    discount = DiscountService.get_valid_discount(db, code_name=code_name)
    if not discount:
        raise HTTPException(
            status_code=404, 
            detail="Mã giảm giá không tồn tại, đã hết hạn hoặc chưa đến thời gian áp dụng"
        )
    return discount

@router.get("/by-categories", response_model=Dict[int, DiscountOut])
def get_discounts_by_categories(
    category_ids: List[int] = Query(...), 
    db: Session = Depends(get_db)
):
    """
    Lấy danh sách giảm giá đang áp dụng cho nhiều danh mục cùng lúc.
    Sử dụng khi hiển thị danh sách sản phẩm để biết sản phẩm nào đang được giảm giá.
    """
    return DiscountService.get_valid_discounts_by_category_ids(db, category_ids)


# --- DÀNH CHO ADMIN (QUẢN LÝ) ---

@router.post("/", response_model=DiscountOut)
def create_discount(discount_in: DiscountBase, db: Session = Depends(get_db)):
    """
    Tạo một chương trình giảm giá mới cho một danh mục.
    """
    # Logic tạo discount đơn giản
    new_discount = Discount(**discount_in.model_dump(), status="ACTIVE")
    db.add(new_discount)
    db.commit()
    db.refresh(new_discount)
    return new_discount