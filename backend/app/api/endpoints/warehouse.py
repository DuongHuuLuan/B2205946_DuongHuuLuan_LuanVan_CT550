from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.schemas.product import ProductQuantityOut
from app.schemas.warehouse import (
    WarehouseCreate,
    WarehouseDetailPaginationOut,
    WarehouseOut,
    WarehousePaginationOut,
)
from app.services.warehouse_service import WarehouseService
from app.api.deps import require_admin

router = APIRouter(prefix="/warehouses", tags=["Warehouse"])


@router.get("/", response_model=WarehousePaginationOut)
def get_all(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
):
    """
    API lay danh sach kho hang
    """
    return WarehouseService.get_all(db, page=page, per_page=per_page, keyword=q)


@router.get("/product-quantity", response_model=ProductQuantityOut)
def get_product_quantity(
    product_id: int = Query(..., description="ID cua san pham"),
    size_id: int = Query(..., description="ID cua kich thuoc"),
    color_id: int = Query(..., description="ID cua mau sac"),
    db: Session = Depends(get_db),
):
    """
    API lay tong so luong ton kho cua mot bien the san pham
    """
    quantity = WarehouseService.get_quantity_product_detail_id(
        db, product_id=product_id, size_id=size_id, color_id=color_id
    )
    return {
        "product_id": product_id,
        "size_id": size_id,
        "color_id": color_id,
        "total_quantity": quantity,
    }


@router.get("/{warehouse_id}", response_model=WarehouseOut)
def get_warehouse(
    warehouse_id: int,
    db: Session = Depends(get_db),
):
    """
    API lay thong tin mot kho
    """
    return WarehouseService.get_id(db, warehouse_id=warehouse_id)


@router.get("/{warehouse_id}/details", response_model=WarehouseDetailPaginationOut)
def get_warehouse_detail(
    warehouse_id: int,
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    category_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """
    API lay danh sach ton kho theo kho
    """
    return WarehouseService.get_warehouse_detail(
        db,
        warehouse_id=warehouse_id,
        page=page,
        per_page=per_page,
        keyword=q,
        category_id=category_id,
    )


@router.post("/", response_model=WarehouseOut, status_code=status.HTTP_201_CREATED)
def create_warehouse(
    warehouse_in: WarehouseCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API tao mot kho moi"""
    return WarehouseService.create_warehouse(db, warehouse_in)


@router.put("/{warehouse_id}", response_model=WarehouseOut)
def update_warehouse(
    warehouse_id: int,
    warehouse_in: WarehouseCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API cap nhat thong tin kho"""
    return WarehouseService.update_warehouse(db, warehouse_id, warehouse_in)


@router.delete("/{warehouse_id}")
def delete_warehouse(
    warehouse_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API xoa kho (chi xoa kho rong)"""
    return WarehouseService.delete_warehouse(db, warehouse_id)
