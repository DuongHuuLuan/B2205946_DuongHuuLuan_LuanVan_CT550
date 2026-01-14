from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, model_validator
from typing import List, Optional
from app.models.order import OrderStatus
from app.schemas import *

#schema cho delivery info
class DeliveryInfoBase(BaseModel):
    name: str
    address: str
    phone: str
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
    order_items: Optional[List[OrderItemCreate]] = None

class OrderStatusUpdate(BaseModel):
    status: OrderStatus


#schema cho Order
class OrderOut(BaseModel):
    id: int
    status: str
    created_at: datetime

    delivery_info: Optional[DeliveryInfoOut]
    payment_method: Optional[PaymentMethodOut]

    order_details: List[OrderDetailOut] = []

    class Config:
        from_attributes = True
