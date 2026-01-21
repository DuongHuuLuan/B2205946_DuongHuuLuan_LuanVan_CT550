from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.product import UnitEnum
from app.schemas.category import CategoryOut
from app.schemas.image_url import ImageUrlOut
from app.schemas.product_detail import ProductDetailCreate, ProductDetailOut
class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    unit: UnitEnum = UnitEnum.CHIEC
    category_id: int

class ImageUloadPayload(BaseModel):
    url: str
    public_id: str
    color_id: Optional[int] = None

class ProductCreate(ProductBase):
    images: List[ImageUloadPayload] =[]
    product_details: List[ProductDetailCreate] =[]

class ProductQuantityOut(BaseModel):
    product_id: int
    size_id: int
    color_id: int
    total_quantity: int

class ProductOut(ProductBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    category: CategoryOut
    product_images: List[ImageUrlOut] = []
    product_details: List[ProductDetailOut] = []

    class Config:
        from_attributes = True

class PaginationMeta(BaseModel):
    total: int # tổng số sản phẩm trong DB
    current_page: int # trang hiện tại
    per_page: int # số mục mỗi trang
    last_page: int # trang cuối cùng(tổng số trang)

class ProductPaginationOut(BaseModel):
    items: List[ProductOut] #danh sách sản phẩm chi tiết
    meta: PaginationMeta

    class Config:
        from_attributes: True