from fastapi import APIRouter, Depends, HTTPException
from app.api import deps
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.api.deps import require_user
from app.schemas.order import DeliveryInfoOut, DeliveryInfoBase
from app.services.delivery_service import DeliveryService

router = APIRouter(prefix="/delivery", tags=["Delivery Info"])

@router.post("/", response_model=DeliveryInfoOut)
def add_address(data: DeliveryInfoBase, db: Session = Depends(get_db), current_user = Depends(deps.get_current_user)):
    return DeliveryService.create_delivery(db, current_user.id, data)

@router.get("/", response_model=list[DeliveryInfoOut])
def get_addresses(db: Session = Depends(get_db), current_user = Depends(deps.get_current_user)):
    return DeliveryService.get_my_deliveries(db, current_user.id)

@router.delete("/{delivery_id}")
def delete_address(
    delivery_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """API xóa một delivery cụ thể"""
    return DeliveryService.delete_delivery(db=db,delivery_id=delivery_id, user_id=current_user.id)