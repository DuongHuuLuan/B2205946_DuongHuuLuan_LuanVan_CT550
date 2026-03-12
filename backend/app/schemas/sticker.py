from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


class StickerBase(BaseModel):
    name: str
    image_url: str
    category: str = "General"
    is_ai_generated: bool = False
    has_transparent_background: bool = False


class StickerOut(StickerBase):
    id: int

    class Config:
        from_attributes = True


class StickerListOut(BaseModel):
    items: List[StickerOut]


class AiStickerGenerateIn(BaseModel):
    prompt: str
    style: Optional[str] = None
    dominant_color: Optional[str] = None
    remove_background: bool = True


class RemoveBackgroundIn(BaseModel):
    image_url: str


class RemoveBackgroundOut(BaseModel):
    image_url: str


class StickerAdminOut(StickerOut):
    owner_user_id: Optional[int] = None
    public_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
