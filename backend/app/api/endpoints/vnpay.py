from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import RedirectResponse
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
    order_id = params.get("vnp_TxnRef", "")
    response_code = params.get("vnp_ResponseCode")
    transaction_status = params.get("vnp_TransactionStatus")
    is_success = response_code == "00" and transaction_status == "00"

    if is_valid:
        VnpayService.handle_ipn(db, params)

    app_return_url = settings.APP_RETURN_URL or (
        f"{settings.APP_DEEP_LINK_SCHEME}://payment-result"
    )
    separator = "&" if "?" in app_return_url else "?"
    redirect_url = (
        f"{app_return_url}{separator}orderId={order_id}"
        f"&status={'success' if (is_valid and is_success) else 'failed'}"
        f"&valid={'1' if is_valid else '0'}"
    )
    return RedirectResponse(url=redirect_url, status_code=302)


@router.get("/ipn")
def vnpay_ipn(request: Request, db: Session = Depends(get_db)):
    params = dict(request.query_params)
    return VnpayService.handle_ipn(db, params)
