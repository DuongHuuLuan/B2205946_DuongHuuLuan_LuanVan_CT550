from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user_optional, require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.sticker import (
    AiStickerGenerateIn,
    RemoveBackgroundIn,
    RemoveBackgroundOut,
    StickerListOut,
    StickerOut,
)
from app.services.sticker_service import StickerService

router = APIRouter(prefix="/stickers", tags=["Stickers"])


@router.get("/", response_model=StickerListOut)
def get_sticker_catalog(
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    items = StickerService.get_catalog(
        db,
        user_id=current_user.id if current_user else None,
    )
    return {"items": items}


@router.post("/generate", response_model=StickerOut, status_code=status.HTTP_501_NOT_IMPLEMENTED)
def generate_ai_sticker(
    sticker_in: AiStickerGenerateIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Chức năng tạo sticker AI sẽ được triển khai ở bước service AI",
    )


@router.post("/remove-background", response_model=RemoveBackgroundOut, status_code=status.HTTP_501_NOT_IMPLEMENTED)
def remove_sticker_background(
    payload: RemoveBackgroundIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Chức năng tách nền sticker sẽ được triển khai ở bước background removal service",
    )
