from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class EvaluateCreate(BaseModel):
    rate: int = Field(..., ge=1, le=5, description="Số sao từ 1 đến 5")
    content: Optional[str] = None


class EvaluateReplyCreate(BaseModel):
    admin_reply: str = Field(..., min_length=1, max_length=2000)

class EvaluateImageOut(BaseModel):
    id: int
    image_url: str
    sort_order: Optional[int] = None

    class Config:
        from_attributes = True


class EvaluateOut(BaseModel):
    id: int
    order_id: int
    user_id: int
    admin_id: Optional[int] = None

    rate: int
    content: Optional[str] = None

    admin_reply: Optional[str] = None
    admin_replied_at: Optional[datetime] = None

    created_at: datetime
    updated_at: Optional[datetime] = None

    images: List[EvaluateImageOut] = Field(default_factory=list)
    
    class Config:
        from_attributes = True


class EvaluatePaginationMeta(BaseModel):
    page: int
    per_page: int
    total: int
    total_pages: int


class EvaluatePaginationOut(BaseModel):
    items: List[EvaluateOut]
    meta: EvaluatePaginationMeta
