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
        variant = getattr(data, "product_variant", None)
        result = data
        if not isinstance(data, dict):
            result = {col.name: getattr(data, col.name) for col in data.__table__.columns}

        if variant:
            # 1. Lấy thông tin sản phẩm và ảnh
            if variant.product:
                result["product_name"] = variant.product.name
                if variant.product.images:
                    # Kiểm tra lại tên trường trong DB của bạn là .url hay .image_url
                    result["image_url"] = variant.product.images[0].url
            
            # 2. Lấy thông tin màu sắc và kích thước
            if variant.color:
                result["color_name"] = variant.color.name
            if variant.size:
                result["size_name"] = variant.size.size
        
        return result

class OrderCreate(BaseModel):
    delivery_info_id: int
    payment_method_id: int
    discount_code: Optional[str] = None

class OrderStatusUpdate(BaseModel):
    status: OrderStatus


#schema cho Order
class OrderOut(BaseModel):
    id: int
    status: str
    rank_discount: Decimal
    created_at: datetime

    delivery_info: Optional[DeliveryInfoOut]
    payment_method: Optional[PaymentMethodOut]

    items: List[OrderDetailOut] = []

    class Config:
        from_attributes = True
