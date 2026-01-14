from fastapi import APIRouter, Depends, Request, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import require_user
from app.core.config import settings
from app.db.session import get_db
from app.models.order import Order
from app.models.user import User
from app.schemas.vnpay import VnpayCreateRequest, VnpayPaymentUrlOut
from app.services.vnpay_service import VnpayService

router = APIRouter(prefix="/vnpay", tags=["VNPAY"])


@router.post("/create-payment", response_model=VnpayPaymentUrlOut)
def create_payment_url(
    payload: VnpayCreateRequest,
    request: Request,
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

    base_url = str(request.base_url).rstrip("/")
    return_url = settings.VNPAY_RETURN_URL or f"{base_url}/vnpay/return"
    ip_address = request.client.host if request.client else "0.0.0.0"

    payment_url = VnpayService.create_payment_url(
        db=db,
        order_id=payload.order_id,
        ip_address=ip_address,
        bank_code=payload.bank_code,
        locale=payload.locale,
        return_url=return_url,
    )
    return {"payment_url": payment_url}


@router.get("/return")
def vnpay_return(request: Request, db: Session = Depends(get_db)):
    params = dict(request.query_params)
    
    if not params:
        raise HTTPException(status_code=400, detail="No data received")
    
    is_valid = VnpayService.verify_signature(params)
    if is_valid:
        VnpayService.record_transaction(db, params)

    return {
        "is_valid": is_valid,
        "received_params": params
    }
    # return {
    #     "valid_signature": is_valid,
    #     "vnp_ResponseCode": params.get("vnp_ResponseCode"),
    #     "vnp_TxnRef": params.get("vnp_TxnRef"),
    #     "vnp_Amount": params.get("vnp_Amount"),
    #     "vnp_OrderInfo": params.get("vnp_OrderInfo"),
    # }


@router.get("/ipn")
def vnpay_ipn(request: Request, db: Session = Depends(get_db)):
    params = dict(request.query_params)
    return VnpayService.handle_ipn(db, params)
