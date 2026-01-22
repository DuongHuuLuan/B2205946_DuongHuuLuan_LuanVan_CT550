from pydantic import BaseModel
from typing import List, Optional

from app.schemas.product import ProductOut
from app.schemas.product_detail import ColorOut, SizeOut


class WarehouseBase(BaseModel):
    address: str
    capacity: Optional[int] = None


class WarehouseCreate(WarehouseBase):
    pass


class WarehouseOut(WarehouseBase):
    id: int
    products_count: int = 0
    total_quantity: int = 0
    pending_quantity: int = 0

    class Config:
        from_attributes = True


class PaginationMeta(BaseModel):
    total: int
    current_page: int
    per_page: int
    last_page: int


class WarehousePaginationOut(BaseModel):
    items: List[WarehouseOut]
    meta: PaginationMeta

    class Config:
        from_attributes = True


class WarehouseDetailItemOut(BaseModel):
    id: int
    product: ProductOut
    color: Optional[ColorOut] = None
    size: Optional[SizeOut] = None
    quantity: int

    class Config:
        from_attributes = True


class WarehouseDetailPaginationOut(BaseModel):
    warehouse: WarehouseOut
    items: List[WarehouseDetailItemOut]
    meta: PaginationMeta

    class Config:
        from_attributes = True
