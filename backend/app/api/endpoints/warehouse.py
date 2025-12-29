from typing import List
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models import Warehouse, WarehouseDetail
from app.models.user import User
from app.schemas.warehouse import WarehouseCreate, WarehouseDetailOut, WarehouseOut
from app.services.warehouse_service import WarehouseService
from app.api.deps import require_admin

router = APIRouter(prefix="/warehouse", tags=["Warehouse"])


@router.get("/", response_model= List[WarehouseOut])
def get_all(
    db: Session = Depends(get_db)
):
    """
    API lấy tất cả kho hàng
    """
    return WarehouseService.get_all(db)

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