from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api.deps import get_db
from app.models import *
from app.schemas import *
from app.services.product_detail_service import ProductDetailService
from app.api.deps import require_admin

router = APIRouter(prefix="/product-details", tags=["Product Details"])


@router.post("/colors", response_model=ColorOut, status_code=status.HTTP_201_CREATED)
def create_color(
    color_in: ColorCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.create_color(db, color_in)


@router.get("/colors", response_model=List[ColorOut])
def get_all_colors(db: Session = Depends(get_db)):
    return ProductDetailService.get_all_colors(db)


@router.post("/sizes", response_model=SizeOut, status_code=status.HTTP_201_CREATED)
def create_size(
    size_in: SizeCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.create_size(db, size_in)


@router.get("/sizes", response_model=List[SizeOut])
def get_all_sizes(db: Session = Depends(get_db)):
    return ProductDetailService.get_all_sizes(db)


@router.put("/sizes/{size_id}", response_model=SizeOut)
def update_size(
    size_id: int,
    size_in: SizeUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.update_size(db, size_id, size_in)


@router.delete("/sizes/{size_id}", status_code=status.HTTP_200_OK)
def delete_size(
    size_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.delete_size(db, size_id)


@router.post("/{product_id}", response_model=ProductDetailOut)
def add_product_detail(
    product_id: int,
    product_detail_in: ProductDetailCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.create_product_detail(db, product_detail_in, product_id)


@router.put("/{product_detail_id}", response_model=ProductDetailOut)
def update_product_detail(
    product_detail_id: int,
    product_detail_in: ProductDetailUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.update_product_detail(db, product_detail_id, product_detail_in)


@router.delete("/{product_detail_id}", status_code=status.HTTP_200_OK)
def delete_product_detail(
    product_detail_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductDetailService.delete_product_detail(db, product_detail_id)
