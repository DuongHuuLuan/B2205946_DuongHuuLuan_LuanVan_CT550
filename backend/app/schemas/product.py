from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.product import UnitEnum
from app.schemas.category import CategoryOut
from app.schemas.image_url import ImageUrlOut
from app.schemas.product_detail import ProductDetailOut
class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    unit: UnitEnum = UnitEnum.CHIEC
    category_id: int

class ImageUloadPayload(BaseModel):
    url: str
    public_id: str

class ProductCreate(ProductBase):
    images: List[ImageUloadPayload] =[]

class ProductOut(ProductBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    category: CategoryOut
    product_images: List[ImageUrlOut] = []
    product_details: List[ProductDetailOut] = []

    class Config:
        from_attributes = True