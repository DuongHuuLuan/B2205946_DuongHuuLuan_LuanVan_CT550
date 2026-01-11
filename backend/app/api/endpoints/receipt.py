from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.schemas import *
from app.models import *
from app.api.deps import require_admin
from app.services.receipt_service import ReceiptService

router = APIRouter(prefix="/receipts", tags=["Receipt"])


@router.post("/", response_model=ReceiptOut, status_code=status.HTTP_201_CREATED)
def create_receipt(receipt_in: ReceiptCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """API tao phieu nhap moi"""
    return ReceiptService.create_receipt(db,receipt_in)

@router.post("/{receipt_id}/confirm", response_model=ReceiptOut)
def confirm_stock(
    receipt_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """API xac nhan hang ve kho thuc te"""
    return ReceiptService.confirm_receipt(db, receipt_id)
