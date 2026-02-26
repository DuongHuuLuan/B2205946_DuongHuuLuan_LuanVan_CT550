from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, model_validator
from typing import List, Optional
from app.models.order import OrderStatus
from app.schemas import *
from app.schemas.discount import DiscountOut

#schema cho delivery info
class DeliveryInfoBase(BaseModel):
    name: str
    address: str
    phone: str
    district_id: Optional[int] = None
    ward_code: Optional[str] = None
    default: bool = False

class DeliveryInfoOut(DeliveryInfoBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

#schema cho Payment method
class PaymentMethodOut(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class PaymentMethodBase(BaseModel):
    name: str


class PaymentMethodCreate(PaymentMethodBase):
    pass


class PaymentMethodUpdate(BaseModel):
    name: Optional[str] = None


class PaymentPaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class PaymentMethodPaginationOut(BaseModel):
    items: List[PaymentMethodOut]
    meta: PaymentPaginationMeta

#schema cho OrderDetail
class OrderDetailOut(BaseModel):
    id: int
    product_detail_id: int
    quantity: int
    price: Decimal 

    product_name: Optional[str] = None
    color_name: Optional[str] = None
    size_name: Optional[str] = None
    image_url: Optional[str] = None

    class Config:
        from_attributes = True

    @model_validator(mode='before')
    @classmethod
    def get_related_data(cls, data):
        product_detail = getattr(data, "product_detail", None)
        result = data
        if not isinstance(data, dict):
            result = {col.name: getattr(data, col.name) for col in data.__table__.columns}

        if product_detail:
            # 1. Lấy thông tin sản phẩm và ảnh
            if product_detail.product:
                result["product_name"] = product_detail.product.name
                if product_detail.product.product_images:
                    # Kiểm tra lại tên trường trong DB của bạn là .url hay .image_url
                    result["image_url"] = product_detail.product.product_images[0].url

            # 2. Lấy thông tin màu sắc và kích thước
            if product_detail.color:
                result["color_name"] = product_detail.color.name
            if product_detail.size:
                result["size_name"] = product_detail.size.size
        
        return result

class OrderItemCreate(BaseModel):
    product_detail_id: int
    quantity: int

class OrderCreate(BaseModel):
    delivery_info_id: int
    payment_method_id: int
    discount_code: Optional[str] = None
    discount_ids: Optional[List[int]] = None
    order_items: Optional[List[OrderItemCreate]] = None

class OrderStatusUpdate(BaseModel):
    status: OrderStatus


#schema cho Order
class OrderOut(BaseModel):
    id: int
    status: str
    created_at: datetime
    shipping_fee: Decimal = Decimal("0")

    delivery_info: Optional[DeliveryInfoOut]
    payment_method: Optional[PaymentMethodOut]
    user: Optional[UserOut] = None
    applied_discounts: List[DiscountOut] = []

    order_details: List[OrderDetailOut] = []

    class Config:
        from_attributes = True

    @model_validator(mode='before')
    @classmethod
    def inject_shipping_fee(cls, data):
        result = data
        if not isinstance(data, dict):
            result = {col.name: getattr(data, col.name) for col in data.__table__.columns}
            for attr in ("delivery_info", "payment_method", "user", "order_details", "applied_discounts"):
                if hasattr(data, attr):
                    result[attr] = getattr(data, attr)

        shipping_fee = result.get("shipping_fee")
        if shipping_fee is None:
            ghn_shipments = None
            if isinstance(data, dict):
                ghn_shipments = data.get("ghn_shipments")
            else:
                ghn_shipments = getattr(data, "ghn_shipments", None)

            fee_value = Decimal("0")
            if ghn_shipments:
                first = ghn_shipments[0]
                raw_fee = (
                    getattr(first, "shipping_fee", None)
                    if not isinstance(first, dict)
                    else first.get("shipping_fee")
                )
                if raw_fee is not None:
                    fee_value = Decimal(str(raw_fee))
            result["shipping_fee"] = fee_value

        return result


class OrderPaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class OrderPaginationOut(BaseModel):
    items: List[OrderOut]
    meta: OrderPaginationMeta
