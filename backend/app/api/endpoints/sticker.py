from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user_optional, require_admin, require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.sticker import (
    AiStickerGenerateIn,
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


@router.get("/admin/system", response_model=StickerAdminPaginationOut)
def get_system_stickers(
    page: int = 1,
    per_page: Optional[int] = None,
    q: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StickerService.list_system_stickers(
        db=db,
        page=page,
        per_page=per_page,
        keyword=q,
        category=category,
    )


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


@router.post("/generate", response_model=StickerOut, status_code=status.HTTP_501_NOT_IMPLEMENTED)
def generate_ai_sticker(
    sticker_in: AiStickerGenerateIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Chuc nang tao sticker AI se duoc trien khai o buoc service AI",
    )


@router.post("/remove-background", response_model=RemoveBackgroundOut, status_code=status.HTTP_501_NOT_IMPLEMENTED)
def remove_sticker_background(
    payload: RemoveBackgroundIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Chuc nang tach nen sticker se duoc trien khai o buoc background removal service",
    )
