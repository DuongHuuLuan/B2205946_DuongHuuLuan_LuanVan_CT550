from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import Optional
from app.db.session import get_db
from app.api.deps import require_admin
from app.schemas.order import (
    PaymentMethodOut,
    PaymentMethodCreate,
    PaymentMethodUpdate,
    PaymentMethodPaginationOut,
)
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/payment", tags=["Payment Method"])


@router.get("/", response_model=list[PaymentMethodOut])
def get_payment_methods(db: Session = Depends(get_db)):
    return PaymentService.get_active_payments(db)


# --- Admin ---

@router.get("/admin", response_model=PaymentMethodPaginationOut)
def get_payment_methods_admin(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
    current_admin = Depends(require_admin),
):
    return PaymentService.get_all(db, page=page, per_page=per_page, keyword=q)


@router.get("/admin/{payment_id}", response_model=PaymentMethodOut)
def get_payment_method_id(
    payment_id: int,
    db: Session = Depends(get_db),
    current_admin = Depends(require_admin),
):
    return PaymentService.get_id(db, payment_id)


@router.post("/admin", response_model=PaymentMethodOut, status_code=status.HTTP_201_CREATED)
def create_payment_method(
    payment_in: PaymentMethodCreate,
    db: Session = Depends(get_db),
    current_admin = Depends(require_admin),
):
    return PaymentService.create(db, payment_in)


@router.put("/admin/{payment_id}", response_model=PaymentMethodOut)
def update_payment_method(
    payment_id: int,
    payment_in: PaymentMethodUpdate,
    db: Session = Depends(get_db),
    current_admin = Depends(require_admin),
):
    return PaymentService.update(db, payment_id, payment_in)


@router.delete("/admin/{payment_id}", status_code=status.HTTP_200_OK)
def delete_payment_method(
    payment_id: int,
    db: Session = Depends(get_db),
    current_admin = Depends(require_admin),
):
    return PaymentService.delete(db, payment_id)
