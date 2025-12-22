from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.schemas.product import ProductCreated, ProductOut
from app.services.product_service import ProductService
from app.services.image_service import ImageService
from app.models.user import User
from app.api.deps import require_admin, require_user
router  = APIRouter(prefix="/products", tags=["Products"])

@router.get("/", response_model=List[ProductOut])
def getAll_product(db: Session = Depends(get_db)):
    """
    API Lấy tất cả sản phẩm
    """
    return ProductService.getAll_product(db)

@router.get("/category/{category_id}", response_model=List[ProductOut])
def get_product_category(category_id: int, db: Session = Depends(get_db)):
    """
    Lấy tất cả sản phẩm thuộc về một danh mục cụ thể
    """
    products = ProductService.get_product_category(db, category_id)
    return products

@router.post("/", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def create_product(product_in: ProductCreated, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API tạo sản phẩm mới
    """

    new_product = ProductService.create_product(db, product_in)
    return new_product

@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """
    API lấy chi tiết một sản phẩm (Bao gồm cả category và Images)
    """
    return ProductService.get_product_byID(db,product_id)


@router.post("/add-to-cart")
def add_to_cart(db: Session = Depends(get_db), current_user: User = Depends(require_user)):
    return {"message": "Đã thêm vào giỏ hàng thành công"}