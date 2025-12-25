from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from app.schemas import *

# du lieu khi them san pham vao gio
class CartItemCreate(BaseModel):
    product_detail_id: int
    quantity: int = 1

#du lieu khi cap nhat so luong trong gio
class CartItemUpdate(BaseModel):
    quantity: int

#schema cau truc hien thi mot mon hang trong gio
class CartItemOut(BaseModel):
    id: int
    product_detail_id: int
    quantity: int
    product_variant: VariantOut

    class Config: 
        from_attributes = True

#schema hien thi toan bo gio hang
class CartOut(BaseModel):
    id: int
    user_id: int
    items: List[CartItemOut]
    total_price: float = 0

    class Config:
        from_attributes = True