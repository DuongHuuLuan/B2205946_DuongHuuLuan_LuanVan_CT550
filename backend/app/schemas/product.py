from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.product import UnitEnum
from app.schemas.category import CategoryOut
from app.schemas.image_url import ImageUrlOut
from app.schemas.variant import VariantOut
class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    unit: UnitEnum = UnitEnum.CHIEC
    category_id: int


class ProductCreate(ProductBase):
    image_urls: List[str] =[]

class ProductOut(ProductBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    category: CategoryOut
    images: List[ImageUrlOut] = []
    variants: List[VariantOut] = []

    class Config:
        from_attributes = True