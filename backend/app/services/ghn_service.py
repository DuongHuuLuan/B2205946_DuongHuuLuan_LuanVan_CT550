import json
from decimal import Decimal
from typing import Any, Optional

import httpx
from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models import Order, OrderDetail, ProductDetail, Product, PaymentMethod
from app.models.ghn import GhnShipment


class GhnService:
    @staticmethod
    def _headers() -> dict:
        if not settings.GHN_TOKEN or not settings.GHN_SHOP_ID:
            raise HTTPException(status_code=400, detail="GHN config is missing")
        return {
            "Token": settings.GHN_TOKEN,
            "ShopId": str(settings.GHN_SHOP_ID),
            "Content-Type": "application/json",
        }

    @staticmethod
    def _request(path: str, payload: dict) -> dict:
        url = f"{settings.GHN_API_BASE.rstrip('/')}{path}"
        try:
            resp = httpx.post(url, json=payload, headers=GhnService._headers(), timeout=20)
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail=f"GHN request failed: {exc}") from exc

        data = resp.json()
        if data.get("code") not in (200, 0):
            raise HTTPException(status_code=400, detail=data.get("message", "GHN error"))
        return data

    @staticmethod
    def _get(path: str, params: dict) -> dict:
        url = f"{settings.GHN_API_BASE.rstrip('/')}{path}"
        try:
            resp = httpx.get(url, params=params, headers=GhnService._headers(), timeout=20)
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail=f"GHN request failed: {exc}") from exc

        data = resp.json()
        if data.get("code") not in (200, 0):
            raise HTTPException(status_code=400, detail=data.get("message", "GHN error"))
        return data

    @staticmethod
    def _order_total(order: Order) -> Decimal:
        total = Decimal("0")
        for detail in order.order_details:
            total += Decimal(str(detail.price)) * detail.quantity
        return max(total, Decimal("0"))

    @staticmethod
    def _load_order(db: Session, order_id: int) -> Order:
        order = (
            db.query(Order)
            .options(
                joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.product),
                joinedload(Order.delivery_info),
                joinedload(Order.payment_method),
            )
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        if not order.delivery_info:
            raise HTTPException(status_code=400, detail="Delivery info is missing")
        return order
    
    #logic tính phí vận chuyển
    @staticmethod
    def calculate_fee(
        db: Session,
        order_id: int,
        to_district_id: int,
        to_ward_code: str,
        service_id: Optional[int] = None,
        service_type_id: Optional[int] = None,
        insurance_value: Optional[Decimal] = None,
    ) -> dict:
        order = GhnService._load_order(db, order_id)

        payload = {
            "to_district_id": to_district_id,
            "to_ward_code": to_ward_code,
            "from_district_id": settings.GHN_FROM_DISTRICT_ID,
            "from_ward_code": settings.GHN_FROM_WARD_CODE,
            "height": settings.GHN_DEFAULT_HEIGHT,
            "length": settings.GHN_DEFAULT_LENGTH,
            "width": settings.GHN_DEFAULT_WIDTH,
            "weight": settings.GHN_DEFAULT_WEIGHT,
            "insurance_value": int(insurance_value or GhnService._order_total(order)),
        }
        if service_id is not None:
            payload["service_id"] = service_id
        if service_type_id is not None:
            payload["service_type_id"] = service_type_id

        data = GhnService._request("/shiip/public-api/v2/shipping-order/fee", payload)
        fee = data.get("data", {})
        return {
            "total": Decimal(str(fee.get("total", 0))),
            "service_fee": Decimal(str(fee.get("service_fee", 0))) if fee.get("service_fee") is not None else None,
            "insurance_fee": Decimal(str(fee.get("insurance_fee", 0))) if fee.get("insurance_fee") is not None else None,
            "raw": fee,
        }

    @staticmethod
    def create_order(
        db: Session,
        order_id: int,
        to_district_id: int,
        to_ward_code: str,
        service_id: Optional[int] = None,
        service_type_id: Optional[int] = None,
        note: Optional[str] = None,
        required_note: Optional[str] = None,
        cod_amount: Optional[Decimal] = None,
        insurance_value: Optional[Decimal] = None,
    ) -> GhnShipment:
        order = GhnService._load_order(db, order_id)
        delivery = order.delivery_info
        total_amount = GhnService._order_total(order)

        if cod_amount is None:
            is_cod = False
            if order.payment_method and isinstance(order.payment_method, PaymentMethod):
                name = (order.payment_method.name or "").lower()
                is_cod = "cod" in name
            cod_amount = total_amount if is_cod else Decimal("0")

        items = []
        for detail in order.order_details:
            product = detail.product_detail.product if detail.product_detail else None
            items.append(
                {
                    "name": product.name if product else "Item",
                    "quantity": detail.quantity,
                    "price": int(detail.price),
                }
            )

        payload = {
            "payment_type_id": settings.GHN_PAYMENT_TYPE_ID,
            "note": note or "",
            "required_note": required_note or settings.GHN_REQUIRED_NOTE,
            "from_name": settings.GHN_FROM_NAME,
            "from_phone": settings.GHN_FROM_PHONE,
            "from_address": settings.GHN_FROM_ADDRESS,
            "from_ward_code": settings.GHN_FROM_WARD_CODE,
            "from_district_id": settings.GHN_FROM_DISTRICT_ID,
            "to_name": delivery.name,
            "to_phone": delivery.phone,
            "to_address": delivery.address,
            "to_ward_code": to_ward_code,
            "to_district_id": to_district_id,
            "cod_amount": int(cod_amount),
            "insurance_value": int(insurance_value or total_amount),
            "weight": settings.GHN_DEFAULT_WEIGHT,
            "length": settings.GHN_DEFAULT_LENGTH,
            "width": settings.GHN_DEFAULT_WIDTH,
            "height": settings.GHN_DEFAULT_HEIGHT,
            "items": items,
        }
        if service_id is not None:
            payload["service_id"] = service_id
        if service_type_id is not None:
            payload["service_type_id"] = service_type_id

        data = GhnService._request("/shiip/public-api/v2/shipping-order/create", payload)
        res = data.get("data", {})

        shipment = GhnShipment(
            order_id=order_id,
            ghn_order_code=res.get("order_code"),
            status=res.get("status"),
            service_id=service_id,
            service_type_id=service_type_id,
            from_name=settings.GHN_FROM_NAME,
            from_phone=settings.GHN_FROM_PHONE,
            from_address=settings.GHN_FROM_ADDRESS,
            from_ward_code=settings.GHN_FROM_WARD_CODE,
            from_district_id=settings.GHN_FROM_DISTRICT_ID,
            to_name=delivery.name,
            to_phone=delivery.phone,
            to_address=delivery.address,
            to_ward_code=to_ward_code,
            to_district_id=to_district_id,
            weight=settings.GHN_DEFAULT_WEIGHT,
            length=settings.GHN_DEFAULT_LENGTH,
            width=settings.GHN_DEFAULT_WIDTH,
            height=settings.GHN_DEFAULT_HEIGHT,
            cod_amount=cod_amount,
            insurance_value=insurance_value or total_amount,
            shipping_fee=Decimal(str(res.get("total_fee", 0))),
            expected_delivery_time=str(res.get("expected_delivery_time") or ""),
            leadtime=str(res.get("leadtime") or ""),
            tracking_url=res.get("tracking_url"),
            note=note or "",
            raw_request=json.dumps(payload, ensure_ascii=True),
            raw_response=json.dumps(res, ensure_ascii=True),
        )
        db.add(shipment)
        db.commit()
        db.refresh(shipment)
        return shipment

    @staticmethod
    def get_order_detail(db: Session, ghn_order_code: str) -> dict:
        payload = {"order_code": ghn_order_code}
        data = GhnService._request("/shiip/public-api/v2/shipping-order/detail", payload)
        return data.get("data", {})

    @staticmethod
    def handle_webhook(db: Session, payload: dict) -> dict:
        order_code = payload.get("order_code") or payload.get("OrderCode")
        if not order_code:
            return {"message": "missing order_code"}

        shipment = (
            db.query(GhnShipment)
            .filter(GhnShipment.ghn_order_code == order_code)
            .first()
        )
        if not shipment:
            return {"message": "shipment not found"}

        shipment.status = payload.get("status") or payload.get("Status")
        shipment.raw_response = json.dumps(payload, ensure_ascii=True)
        db.commit()
        return {"message": "ok"}

    @staticmethod
    def get_provinces() -> list[dict]:
        data = GhnService._get("/shiip/public-api/master-data/province", {})
        return data.get("data", [])

    @staticmethod
    def get_districts(province_id: int) -> list[dict]:
        data = GhnService._get("/shiip/public-api/master-data/district", {"province_id": province_id})
        return data.get("data", [])

    @staticmethod
    def get_wards(district_id: int) -> list[dict]:
        data = GhnService._get("/shiip/public-api/master-data/ward", {"district_id": district_id})
        return data.get("data", [])

    @staticmethod
    def get_services(to_district_id: int) -> list[dict]:
        payload = {
            "shop_id": int(settings.GHN_SHOP_ID),
            "from_district": settings.GHN_FROM_DISTRICT_ID,
            "to_district": to_district_id,
        }
        data = GhnService._request("/shiip/public-api/v2/shipping-order/available-services", payload)
        return data.get("data", [])

