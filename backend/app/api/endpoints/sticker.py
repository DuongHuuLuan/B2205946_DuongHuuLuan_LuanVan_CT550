from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user_optional, require_admin, require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.sticker import (
    AiStickerGenerateIn,
    AiStickerTranscriptionOut,
    RemoveBackgroundIn,
    RemoveBackgroundOut,
    StickerAdminOut,
    StickerAdminPaginationOut,
    StickerCreate,
    StickerListOut,
    StickerOut,
    StickerUpdate,
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


@router.get("/admin", response_model=StickerAdminPaginationOut)
def get_admin_stickers(
    page: int = 1,
    per_page: Optional[int] = None,
    q: Optional[str] = None,
    category: Optional[str] = None,
    scope: Optional[str] = "system",
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.list_admin_stickers(
        db=db,
        page=page,
        per_page=per_page,
        keyword=q,
        category=category,
        scope=scope,
    )


@router.get("/admin/{sticker_id}", response_model=StickerAdminOut)
def get_admin_sticker(
    sticker_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.get_admin_sticker(db=db, sticker_id=sticker_id)


@router.get("/admin/system/{sticker_id}", response_model=StickerAdminOut)
def get_system_sticker(
    sticker_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.get_system_sticker(db=db, sticker_id=sticker_id)


@router.post("/admin/system", response_model=StickerAdminOut, status_code=status.HTTP_201_CREATED)
def create_system_sticker(
    sticker_in: StickerCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.create_system_sticker(db=db, sticker_in=sticker_in)


@router.put("/admin/system/{sticker_id}", response_model=StickerAdminOut)
def update_system_sticker(
    sticker_id: int,
    sticker_in: StickerUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.update_system_sticker(
        db=db,
        sticker_id=sticker_id,
        sticker_in=sticker_in,
    )


@router.delete("/admin/system/{sticker_id}", status_code=status.HTTP_200_OK)
def delete_system_sticker(
    sticker_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.delete_system_sticker(db=db, sticker_id=sticker_id)


@router.post("/generate", response_model=StickerOut, status_code=status.HTTP_201_CREATED)
def generate_ai_sticker(
    sticker_in: AiStickerGenerateIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return StickerService.generate_ai_sticker(
        db=db,
        user_id=current_user.id,
        sticker_in=sticker_in,
    )


@router.post("/transcribe-voice", response_model=AiStickerTranscriptionOut, status_code=status.HTTP_200_OK)
async def transcribe_ai_sticker_voice(
    audio: UploadFile = File(...),
    current_user: User = Depends(require_user),
):
    audio_bytes = await audio.read()
    prompt = StickerService.transcribe_voice_prompt(
        filename=audio.filename or "ai-sticker-voice.m4a",
        content_type=audio.content_type,
        audio_bytes=audio_bytes,
    )
    return {"prompt": prompt}


# @router.post("/remove-background", response_model=RemoveBackgroundOut, status_code=status.HTTP_501_NOT_IMPLEMENTED)
# def remove_sticker_background(
#     payload: RemoveBackgroundIn,
#     db: Session = Depends(get_db),
#     current_user: User = Depends(require_user),
# ):
#     raise HTTPException(
#         status_code=status.HTTP_501_NOT_IMPLEMENTED,
#         detail="Chức năng tách nền sticker sẽ được triển khai ở bước background removal service",
#     )
