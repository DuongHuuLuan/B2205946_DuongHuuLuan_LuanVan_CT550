from pydantic import BaseModel
from typing import Optional
## schema Color
class ColorBase(BaseModel):
    name: str
    hexcode: str

class ColorCreate(ColorBase):
    pass

class ColorOut(ColorBase):
    id: int
    class Config:
        from_attributes = True


#schema Size
class SizeBase(BaseModel):
    size: str

class SizeCreate(SizeBase):
    pass

class SizeOut(SizeBase):
    id: int
    class Config:
        from_attributes = True


#schema Product_detail 
class ProductDetailCreate(BaseModel):
    color_id: int
    size_id: int
    price: int
    stock_quantity: int


class ProductDetailOut(BaseModel):
    id: int
    color: ColorOut
    size: SizeOut
    price: int
    stock_quantity: int
    class Config:
        from_attributes = True
