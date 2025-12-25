from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel
from typing import List, Optional
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

    @classmethod
    def from_orm(cls, obj):
        """Custom để lấy dữ liệu từ các bảng liên quan qua relationship"""
        d = super().from_orm(obj)
        variant = obj.product_variant
        if variant:
            #lấy tên từ product
            if variant.product:
                d.product_name = variant.product.name
                #lấy ảnh đầu tiên từ danh sách ảnh của Product
                if variant.product.images:
                    d.image_url = variant.product.images[0].url

            #lấy tên màu và size
            if variant.color:
                d.color_name = variant.color.name
            if variant.size:
                d.size_name = variant.size.name
        return d

class OrderCreate(BaseModel):
    delivery_info_id: int
    payment_method_id: int

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
