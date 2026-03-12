from typing import Dict, List, Optional

from fastapi import HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models import Sticker
from app.services.base import BaseService


class StickerService(BaseService):
    @staticmethod
    def get_catalog(db: Session, user_id: Optional[int] = None) -> List[Sticker]:
        query = db.query(Sticker)

        if user_id is None:
            query = query.filter(Sticker.owner_user_id.is_(None))
        else:
            query = query.filter(
                or_(
                    Sticker.owner_user_id.is_(None),
                    Sticker.owner_user_id == user_id,
                )
            )

        return (
            query.order_by(
                Sticker.owner_user_id.isnot(None).desc(),
                Sticker.id.desc(),
            ).all()
        )

    @staticmethod
    def get_accessible_sticker_map(
        db: Session,
        sticker_ids: List[int],
        user_id: int,
    ) -> Dict[int, Sticker]:
        normalized_ids = list(dict.fromkeys(sticker_ids))
        if not normalized_ids:
            return {}

        stickers = (
            db.query(Sticker)
            .filter(Sticker.id.in_(normalized_ids))
            .filter(
                or_(
                    Sticker.owner_user_id.is_(None),
                    Sticker.owner_user_id == user_id,
                )
            )
            .all()
        )

        sticker_map = {sticker.id: sticker for sticker in stickers}
        missing_ids = [sticker_id for sticker_id in normalized_ids if sticker_id not in sticker_map]
        if missing_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sticker không hợp lệ hoặc bạn không có quyền sử dụng sticker này",
            )

        return sticker_map
