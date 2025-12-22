from pydantic import BaseModel, HttpUrl
from datetime import datetime
from typing import Optional, List

class ImageURLBase(BaseModel):
    url: str


class ImageURLCreate(ImageURLBase):
    product_id: int

class ImageUrlOut(ImageURLBase):
    id: int
    product_id: int
    created_at: datetime

    class Config:
        from_attributes = True