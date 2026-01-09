from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api.deps import get_db
from app.models import *
from app.schemas import *
from app.services.product_detail_service import ProductDetailService
from app.api.deps import require_admin

router = APIRouter(prefix="/product-details", tags=["Product Details"])

@router.post("/colors", response_model= ColorOut, status_code=status.HTTP_201_CREATED)
def create_color(color_in: ColorCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API tạo màu sắc mới (ADMIN)
    """
    return ProductDetailService.create_color(db,color_in)
@router.get("/colors", response_model= List[ColorOut])
def get_all_colors(db: Session = Depends(get_db)):
    """ Lấy danh sách tất cả màu """
    return ProductDetailService.get_all_colors(db)          

@router.post("/sizes", response_model= SizeOut, status_code=status.HTTP_201_CREATED)
def create_size(size_in: SizeCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """ API tạo kích thước mới (ADMIN)"""
    return ProductDetailService.create_size(db, size_in)

@router.get("/sizes", response_model= List[SizeOut])
def get_all_sizes(db: Session = Depends(get_db)):
    """API lấy tất cả các size"""
    return ProductDetailService.get_all_sizes(db)

@router.post("/product-details/{product_id}", response_model= ProductDetailOut)
def add_product_detail(product_id: int, variant_in: ProductDetailCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """Gán một biến thể (Màu + Size + Tồn kho) cho một sản phẩm cụ thể """
    return ProductDetailService.create_variant(db,variant_in, product_id)

@router.put("/product-details/{product_detail_id}", response_model=ProductDetailOut)
def update_product_detail(
    product_detail_id: int,
    new_quantity: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    return ProductDetailService.update_variant(db, product_detail_id, new_quantity)

@router.delete("/product-details/{product_detail_id}", status_code=status.HTTP_200_OK)
def delete_product_detail(
    product_detail_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    return ProductDetailService.delete_variant(db,product_detail_id)