from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_user
from app.db.session import get_db
from app.models import Order
from app.models.ghn import GhnShipment
from app.models.user import User
from app.schemas.ghn import GhnFeeRequest, GhnFeeOut, GhnCreateOrderRequest, GhnShipmentOut
from app.services.ghn_service import GhnService

router = APIRouter(prefix="/ghn", tags=["GHN"])


@router.post("/fee", response_model=GhnFeeOut)
def calculate_fee(
    payload: GhnFeeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == payload.order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    result = GhnService.calculate_fee(
        db=db,
        order_id=payload.order_id,
        to_district_id=payload.to_district_id,
        to_ward_code=payload.to_ward_code,
        service_id=payload.service_id,
        service_type_id=payload.service_type_id,
        insurance_value=payload.insurance_value,
    )
    return {
        "total": result["total"],
        "service_fee": result["service_fee"],
        "insurance_fee": result["insurance_fee"],
    }


@router.post("/create-order", response_model=GhnShipmentOut)
def create_ghn_order(
    payload: GhnCreateOrderRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == payload.order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    shipment = GhnService.create_order(
        db=db,
        order_id=payload.order_id,
        to_district_id=payload.to_district_id,
        to_ward_code=payload.to_ward_code,
        service_id=payload.service_id,
        service_type_id=payload.service_type_id,
        note=payload.note,
        required_note=payload.required_note,
        cod_amount=payload.cod_amount,
        insurance_value=payload.insurance_value,
    )
    return shipment


@router.get("/order/{order_id}", response_model=GhnShipmentOut)
def get_ghn_status(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    shipment = (
        db.query(GhnShipment)
        .filter(GhnShipment.order_id == order_id)
        .order_by(GhnShipment.created_at.desc())
        .first()
    )
    if not shipment:
        raise HTTPException(status_code=404, detail="GHN shipment not found")

    detail = GhnService.get_order_detail(db, shipment.ghn_order_code)
    shipment.status = detail.get("status") or shipment.status
    db.commit()
    db.refresh(shipment)
    return shipment


@router.post("/webhook")
def ghn_webhook(payload: dict, db: Session = Depends(get_db)):
    return GhnService.handle_webhook(db, payload)


@router.get("/provinces")
def list_provinces(current_user: User = Depends(require_user)):
    return GhnService.get_provinces()


@router.get("/districts/{province_id}")
def list_districts(province_id: int, current_user: User = Depends(require_user)):
    return GhnService.get_districts(province_id)


@router.get("/wards/{district_id}")
def list_wards(district_id: int, current_user: User = Depends(require_user)):
    return GhnService.get_wards(district_id)


@router.get("/services")
def list_services(to_district_id: int, current_user: User = Depends(require_user)):
    return GhnService.get_services(to_district_id)
