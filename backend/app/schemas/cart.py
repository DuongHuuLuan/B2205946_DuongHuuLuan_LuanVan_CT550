from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from app.schemas import *
from app.schemas.product_detail import ProductDetailOut

# du lieu khi them san pham vao gio
class CartDetailCreate(BaseModel):
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int = 1

#du lieu khi cap nhat so luong trong gio
class CartDetailUpdate(BaseModel):
    quantity: int

#schema cau truc hien thi mot mon hang trong gio
class CartDetailOut(BaseModel):
    id: int
    product_detail_id: int
    design_id: Optional[int] = None
    quantity: int
    product_detail: ProductDetailOut
    product_id: int
    product_name: str
    image_url: Optional[str] = None
    design_name: Optional[str] = None
    design_preview_image_url: Optional[str] = None

    is_active: bool = True
    available_stock: int = 0
    cart_status: str = "ok"
    status_message: Optional[str] = None
    can_checkout: bool = True

    class Config: 
        from_attributes = True

#schema hien thi toan bo gio hang
class CartOut(BaseModel):
    id: int
    user_id: int
    cart_details: List[CartDetailOut]
    total_price: float = 0
    can_checkout: bool = True

    class Config:
        from_attributes = True
