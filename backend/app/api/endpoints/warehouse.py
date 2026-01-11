from typing import List
from fastapi import APIRouter, Depends, Query, status, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models import Warehouse, WarehouseDetail
from app.models.user import User
from app.schemas.product import ProductQuantityOut
from app.schemas.warehouse import WarehouseCreate, WarehouseDetailOut, WarehouseOut
from app.services.warehouse_service import WarehouseService
from app.api.deps import require_admin

router = APIRouter(prefix="/warehouses", tags=["Warehouse"])


@router.get("/", response_model= List[WarehouseOut])
def get_all(
    db: Session = Depends(get_db)
):
    """
    API lấy tất cả kho hàng
    """
    return WarehouseService.get_all(db)


@router.get("/product-quantity", response_model= ProductQuantityOut)
def get_product_quantity(
    product_id: int = Query(..., description="ID của sản phẩm"),
    size_id: int = Query(..., description="ID của kích thước"),
    color_id: int = Query(..., description="ID của màu sắc"),
    db: Session = Depends(get_db)
):
    """
    API lấy tổng số lượng tồn kho của một biến thể sản phẩm (theo màu và size) trên tất cả các kho.
    """
    quantity = WarehouseService.get_quantity_product_detail_id(
        db, 
        product_id=product_id, 
        size_id=size_id, 
        color_id=color_id
    )
    
    return {
        "product_id": product_id,
        "size_id": size_id,
        "color_id": color_id,
        "total_quantity": quantity
    }



@router.get("/{warehouse_id}", response_model= List[WarehouseDetailOut])
def get_warehouse_detail(
    warehouse_id: int,
    db: Session = Depends(get_db)
):
    """API lấy thông tin chi tiết của một kho hàng cụ thể"""
    return WarehouseService.get_warehouse_detail(db, warehouse_id=warehouse_id)

@router.post("/", response_model=WarehouseOut, status_code=status.HTTP_201_CREATED)
def create_warehouse(
    warehouse_in: WarehouseCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """ API tạo một kho hàng mới"""
    return WarehouseService.create_warehouse(db, warehouse_in)



@router.put("/{warehouse_id}", response_model=WarehouseOut)
def update_warehouse(
    warehouse_id: int,
    warehouse_in: WarehouseCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """API cập nhật thông tin kho hàng"""
    return WarehouseService.update_warehouse(db, warehouse_id, warehouse_in)


@router.delete("/{warehouse_id}")
def delete_warehouse(warehouse_id: int, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """API xóa kho (chỉ xóa kho rỗng)"""
    return WarehouseService.delete_warehouse(db, warehouse_id)

