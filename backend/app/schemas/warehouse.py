from pydantic import BaseModel
from typing import Optional

class WarehouseBase(BaseModel):
    address: str
    capacity: Optional[int] = None

class WarehouseCreate(WarehouseBase):
    pass 

class WarehouseOut(WarehouseBase):
    id: int

    class Config:
        from_attributes = True

#schema hien thi ton kho thuc te
class WarehouseDetailOut(BaseModel):
    warehouse_id: int
    product_detail_id: int
    quantity: int
    
    class Config:
        from_attributes = True