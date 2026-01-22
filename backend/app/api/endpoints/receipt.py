from typing import Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.receipt import ReceiptCreate, ReceiptOut, ReceiptPaginationOut
from app.models.user import User
from app.api.deps import require_admin
from app.services.receipt_service import ReceiptService

router = APIRouter(prefix="/receipts", tags=["Receipt"])


@router.get("/", response_model=ReceiptPaginationOut)
def get_all_receipts(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.get_all(db, page=page, per_page=per_page, keyword=q)


@router.get("/{receipt_id}", response_model=ReceiptOut)
def get_receipt(
    receipt_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.get_by_id(db, receipt_id)


@router.post("/", response_model=ReceiptOut, status_code=status.HTTP_201_CREATED)
def create_receipt(
    receipt_in: ReceiptCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.create_receipt(db, receipt_in)


@router.post("/{receipt_id}/confirm", response_model=ReceiptOut)
def confirm_receipt(
    receipt_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.confirm_receipt(db, receipt_id)


@router.post("/{receipt_id}/cancel", response_model=ReceiptOut)
def cancel_receipt(
    receipt_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.cancel_receipt(db, receipt_id)


@router.post("/{receipt_id}/approve", response_model=ReceiptOut)
def approve_receipt(
    receipt_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.confirm_receipt(db, receipt_id)


@router.post("/{receipt_id}/reject", response_model=ReceiptOut)
def reject_receipt(
    receipt_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ReceiptService.cancel_receipt(db, receipt_id)
