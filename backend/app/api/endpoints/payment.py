from fastapi import APIRouter, Depends, HTTPException
from app.api import deps
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.api.deps import require_user
from app.schemas.order import DeliveryInfoOut, DeliveryInfoBase
from app.schemas.order import PaymentMethodOut
from app.services.payment_service import PaymentService


router = APIRouter(prefix="/payment", tags=["Payment Method"])

@router.get("/", response_model=list[PaymentMethodOut])
def get_payment_methods(db: Session = Depends(get_db)):
    return PaymentService.get_active_payments(db)