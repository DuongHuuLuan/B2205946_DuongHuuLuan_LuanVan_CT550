from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from decimal import Decimal

# schema chi tiet tung mon trong phieu nhap
class ReceiptDetailBase(BaseModel):
    product_detail_id: int
    quantity: int
    purchase_price: Decimal

class ReceiptDetailCreate(ReceiptDetailBase):
    pass 

class ReceiptDetailOut(ReceiptDetailBase):
    id: int
    class Config:
        from_attributes = True
        
#thong tin tong quat phieu nhap
class ReceiptCreate(BaseModel):
    warehouse_id: int
    distributor_id: int
    details: List[ReceiptDetailCreate]


class ReceiptOut(BaseModel):
    id: int
    warehouse_id: int
    distributor_id: int
    status: str
    created_at: datetime
    details: List[ReceiptDetailOut]


    class Config:
        from_attributes = True