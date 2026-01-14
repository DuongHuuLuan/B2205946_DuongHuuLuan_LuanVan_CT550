import hashlib
import hmac
from datetime import datetime
from decimal import Decimal
from urllib.parse import urlencode
from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models.order import Order, OrderStatus
from app.models.vnpay import VnPayTransaction


class VnpayService:
    @staticmethod
    def _hash_data(data: str) -> str:
        secret = settings.VNPAY_HASH_SECRET or ""
        return hmac.new(secret.encode("utf-8"), data.encode("utf-8"), hashlib.sha512).hexdigest()

    @staticmethod
    def _build_query(params: dict) -> str:
        return urlencode(sorted(params.items()))

    @staticmethod
    def _get_order_total(order: Order) -> Decimal:
        total = Decimal("0")
        for detail in order.order_details:
            total += Decimal(str(detail.price)) * detail.quantity
        return max(total, Decimal("0"))

    @staticmethod
    def create_payment_url(
        db: Session,
        order_id: int,
        ip_address: str,
        bank_code: Optional[str] = None,
        locale: Optional[str] = "vn",
        return_url: Optional[str] = None,
    ) -> str:
        order = (
            db.query(Order)
            .options(joinedload(Order.order_details))
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")

        if not settings.VNPAY_TMN_CODE or not settings.VNPAY_HASH_SECRET:
            raise HTTPException(status_code=400, detail="Cấu hình VNPAY bị thiếu")

        amount = VnpayService._get_order_total(order)
        if amount <= 0:
            raise HTTPException(status_code=400, detail="Số tiền đặt hàng không hợp lệ")

        vnp_return_url = return_url or settings.VNPAY_RETURN_URL
        if not vnp_return_url:
            raise HTTPException(status_code=400, detail="Thiếu VNPAY_RETURN_URL")

        params = {
            "vnp_Version": settings.VNPAY_VERSION,
            "vnp_Command": "pay",
            "vnp_TmnCode": settings.VNPAY_TMN_CODE,
            "vnp_Amount": int(amount * 100),
            "vnp_CurrCode": "VND",
            "vnp_TxnRef": str(order.id),
            "vnp_OrderInfo": f"Thanh toán đơn hàng {order.id}",
            "vnp_OrderType": "other",
            "vnp_Locale": locale or "vn",
            "vnp_ReturnUrl": vnp_return_url,
            "vnp_IpAddr": ip_address,
            "vnp_CreateDate": datetime.now().strftime("%Y%m%d%H%M%S"),
        }
        if bank_code:
            params["vnp_BankCode"] = bank_code

        query = VnpayService._build_query(params)
        secure_hash = VnpayService._hash_data(query)
        return f"{settings.VNPAY_URL}?{query}&vnp_SecureHash={secure_hash}"

    @staticmethod
    def verify_signature(params: dict) -> bool:
        if not params:
            return False

        params = dict(params)
        vnp_secure_hash = params.pop("vnp_SecureHash", None)
        params.pop("vnp_SecureHashType", None)

        query = VnpayService._build_query(params)
        expected = VnpayService._hash_data(query)
        return (vnp_secure_hash or "").lower() == expected.lower()

    @staticmethod
    def record_transaction(db: Session, params: dict) -> VnPayTransaction:
        amount_raw = params.get("vnp_Amount")
        amount = Decimal(amount_raw or 0) / Decimal("100")
        response_code = params.get("vnp_ResponseCode")
        transaction_status = params.get("vnp_TransactionStatus")
        status = "success" if response_code == "00" and transaction_status == "00" else "failed"

        try:
            order_id = int(params.get("vnp_TxnRef") or 0)
        except ValueError:
            order_id = 0
        transaction_no = params.get("vnp_TransactionNo")
        txn_ref = str(params.get("vnp_TxnRef") or "")

        if transaction_no:
            existing = (
                db.query(VnPayTransaction)
                .filter(
                    VnPayTransaction.txn_ref == txn_ref,
                    VnPayTransaction.transaction_no == transaction_no,
                )
                .first()
            )
            if existing:
                return existing

        txn = VnPayTransaction(
            order_id=order_id,
            txn_ref=txn_ref,
            amount=amount,
            response_code=response_code,
            status=status,
            transaction_no=transaction_no,
            bank_code=params.get("vnp_BankCode"),
            pay_date=params.get("vnp_PayDate"),
            message=params.get("vnp_Message"),
        )
        db.add(txn)
        db.commit()
        db.refresh(txn)
        return txn

    @staticmethod
    def handle_ipn(db: Session, params: dict) -> dict:
        if not VnpayService.verify_signature(params):
            return {"RspCode": "97", "Message": "Chữ ký không hợp lệ"}

        try:
            order_id = int(params.get("vnp_TxnRef") or 0)
        except ValueError:
            return {"RspCode": "01", "Message": "Không tìm thấy đơn hàng"}
        order = (
            db.query(Order)
            .options(joinedload(Order.order_details))
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            return {"RspCode": "01", "Message": "Không tìm thấy đơn hàng"}

        amount = Decimal(params.get("vnp_Amount") or 0) / Decimal("100")
        expected_amount = VnpayService._get_order_total(order)
        if amount != expected_amount:
            return {"RspCode": "04", "Message": "Số tiền không hợp lệ"}

        VnpayService.record_transaction(db, params)

        response_code = params.get("vnp_ResponseCode")
        transaction_status = params.get("vnp_TransactionStatus")
        if response_code == "00" and transaction_status == "00":
            if order.status == OrderStatus.PENDING:
                order.status = OrderStatus.SHIPPING
                db.commit()
        return {"RspCode": "00", "Message": "Xác nhận thành công"}
