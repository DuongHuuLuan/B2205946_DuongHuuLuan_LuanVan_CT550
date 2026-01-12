from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


class DiscountBase(BaseModel):
    category_id: int
    name: str
    description: str
    percent: Decimal
    start_at: datetime
    end_at: datetime


class DiscountOut(DiscountBase):
    id: int
    status: str
    class Config: from_attributes = True
