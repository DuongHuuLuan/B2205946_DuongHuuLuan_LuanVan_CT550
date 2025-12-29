from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.api.deps import require_admin
from typing import List
from app.models.distributor import Distributor
from app.models.user import User
from app.schemas.distributor import DistributorCreate, DistributorOut
from app.services.distriburtor_service import DistributorService

router = APIRouter(prefix="/distributors", tags=["Distributors"])

@router.get("/", response_model=List[DistributorOut])
def get_all(
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """ Lấy tất cả nhà cung cấp"""
    return DistributorService.get_all(db)

@router.post("/", response_model=DistributorOut, status_code=status.HTTP_201_CREATED)
def create_distributor(
    distributor_in: DistributorCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_db)
):
    """
    API tạo nhà cung cấp mới (ADMIN)
    """
    return DistributorService.create_distributor(db, distributor_in)


@router.put("/{distributor_id}", response_model=DistributorOut)
def update_distributor(
    distributor_id: int,
    distributor_in: DistributorCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """
    API cập nhật một nhà cung cấp(ADMIN)
    """
    return DistributorService.update_distributor(db,distributor_id, distributor_in)


@router.delete("/{distributor_id}", status_code=status.HTTP_200_OK)
def delete_distributor(
    distributor_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """
    APi xóa một nhà cung cấp cụ thể (ADMIn)
    """
    return DistributorService.delete_distributor(db, distributor_id)