from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session
from typing import List, Optional

import cloudinary.uploader
from app.db.session import get_db
from app.schemas.product import ProductCreate, ProductOut, ProductPaginationOut
from app.services.product_service import ProductService
from app.services.image_service import ImageService
from app.models.user import User
from app.api.deps import require_admin, require_user
router  = APIRouter(prefix="/products", tags=["Products"])

@router.get("/", response_model=ProductPaginationOut)
def getAll_product(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
):
    """
    API Lấy tất cả sản phẩm
    """
    return ProductService.get_products_paginated(
        db,
        page=page,
        per_page=per_page,
        keyword=q,
    )

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
    if product_in.images:
        ImageService.add_images(db,product_id=new_product.id, images=[img.model_dump() for img in product_in.images])
    
    return ProductService.get_product_byID(db,new_product.id)


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """
    API lấy chi tiết một sản phẩm (Bao gồm cả category và Images)
    """
    return ProductService.get_product_byID(db,product_id)


@router.put("/{product_id}", response_model= ProductOut)
def update_product(product_id: int,product_in: ProductCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API cập nhật sản phẩm
    """
    update_product =  ProductService.update_product(db,product_id,product_in)

    if product_in.images is not None:
        ImageService.deleteAll_image(db,product_id)
        ImageService.add_images(db, product_id, images=[img.model_dump() for img in product_in.images])
    
    return ProductService.get_product_byID(db, product_id)

@router.delete("/{product_id}", status_code=status.HTTP_200_OK)
def delete_product(product_id: int, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API xóa 1 sản phẩm theo Id
    """
    ImageService.deleteAll_image(db, product_id)
    return ProductService.delete_product(db,product_id)


@router.post("/{product_id}/images")
def upload_product_images(
    product_id: int,
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    if not files:
        raise HTTPException(status_code=400, detail="Không có file nào")

    uploaded = []
    for f in files:
        r = cloudinary.uploader.upload(f.file, folder="helmet_shop/products")
        uploaded.append({"url": r["secure_url"], "public_id": r["public_id"]})

    # lưu DB
    db_images = ImageService.add_images(db, product_id, uploaded)

    return {
        "count": len(db_images),
        "items": [
            {"id": img.id, "url": img.url, "public_id": img.public_id}
            for img in db_images
        ],
    }
