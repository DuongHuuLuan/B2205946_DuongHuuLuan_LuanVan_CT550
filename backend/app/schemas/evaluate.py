from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from decimal import Decimal

class EvaluateCreate(BaseModel):
    rate: int = Field(..., ge=1, le=5, description="Số sao từ 1 đến 5")
    content: Optional[str] = None
    image: Optional[str] = None


class EvaluateOut(BaseModel):
    id: int
    order_id: int
    user_id: int
    rate: int
    content: str
    image: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True