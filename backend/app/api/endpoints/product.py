from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.schemas.product import ProductCreate, ProductOut
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
def create_product(
    product_in: ProductCreate, 
    db: Session = Depends(get_db), 
    current_admin: User = Depends(require_admin)):
    """
    API tạo sản phẩm mới
    """

    new_product = ProductService.create_product(db, product_in)
    if product_in.image_urls:
        ImageService.add_images(db,product_id=new_product.id, image_urls=product_in.image_urls)
    
    # db.refresh(new_product)
    # return new_product
    return ProductService.get_product_byID(db,new_product.id)


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """
    API lấy chi tiết một sản phẩm (Bao gồm cả category và Images)
    """
    return ProductService.get_product_byID(db,product_id)


@router.put("/{product_id}", response_model= ProductCreate)
def update_product(product_id: int,product_in: ProductCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API cập nhật sản phẩm
    """
    return ProductService.update_product(db,product_id,product_in)

@router.delete("/{product_id}", status_code=status.HTTP_200_OK)
def delete_product(product_id: int, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API xóa 1 sản phẩm theo Id
    """
    return ProductService.delete_product(db,product_id)
