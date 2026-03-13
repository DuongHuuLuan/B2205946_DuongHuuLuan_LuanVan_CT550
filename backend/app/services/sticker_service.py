import math
import re
import uuid
from typing import Dict, List, Optional

from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models import DesignLayer, Sticker
from app.schemas.sticker import StickerCreate, StickerUpdate
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
                detail="Sticker không hợp lệ hoặc bạn không có quyền sở hữu sticker này",
            )

        return sticker_map

    @staticmethod
    def _system_sticker_usage_query(db: Session):
        return (
            db.query(
                Sticker,
                func.count(DesignLayer.id).label("usage_count"),
            )
            .outerjoin(DesignLayer, DesignLayer.sticker_id == Sticker.id)
            .filter(Sticker.owner_user_id.is_(None))
            .group_by(Sticker.id)
        )

    @staticmethod
    def _attach_usage_fields(sticker: Sticker, usage_count: int) -> Sticker:
        normalized_usage = int(usage_count or 0)
        setattr(sticker, "usage_count", normalized_usage)
        setattr(sticker, "can_delete", normalized_usage == 0)
        return sticker

    @staticmethod
    def list_system_stickers(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        category: Optional[str] = None,
    ) -> dict:
        base_query = db.query(Sticker).filter(Sticker.owner_user_id.is_(None))

        if keyword:
            like_pattern = f"%{keyword.strip()}%"
            base_query = base_query.filter(
                or_(
                    Sticker.name.ilike(like_pattern),
                    Sticker.category.ilike(like_pattern),
                    Sticker.image_url.ilike(like_pattern),
                )
            )

        if category:
            base_query = base_query.filter(Sticker.category.ilike(category.strip()))

        total_count = base_query.count()
        if total_count == 0:
            return {
                "items": [],
                "meta": {
                    "total": 0,
                    "current_page": 1,
                    "per_page": per_page or 0,
                    "last_page": 1,
                },
            }

        if per_page is None:
            per_page = total_count
            page = 1
        else:
            per_page = max(int(per_page), 1)
            page = max(int(page), 1)

        skip = (page - 1) * per_page
        usage_query = StickerService._system_sticker_usage_query(db)

        if keyword:
            like_pattern = f"%{keyword.strip()}%"
            usage_query = usage_query.filter(
                or_(
                    Sticker.name.ilike(like_pattern),
                    Sticker.category.ilike(like_pattern),
                    Sticker.image_url.ilike(like_pattern),
                )
            )

        if category:
            usage_query = usage_query.filter(Sticker.category.ilike(category.strip()))

        rows = (
            usage_query.order_by(Sticker.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        items = [
            StickerService._attach_usage_fields(sticker, usage_count)
            for sticker, usage_count in rows
        ]

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": math.ceil(total_count / per_page),
            },
        }

    @staticmethod
    def _normalize_public_id(
        name: str,
        public_id: Optional[str] = None,
    ) -> str:
        normalized = (public_id or "").strip()
        if normalized:
            return normalized

        slug = re.sub(r"[^a-z0-9]+", "-", (name or "").strip().lower()).strip("-")
        if not slug:
            slug = "system-sticker"
        return f"{slug}-{uuid.uuid4().hex[:10]}"

    @staticmethod
    def get_system_sticker(db: Session, sticker_id: int) -> Sticker:
        row = (
            StickerService._system_sticker_usage_query(db)
            .filter(Sticker.id == sticker_id)
            .first()
        )
        if not row:
            raise HTTPException(status_code=404, detail="System sticker not found")

        sticker, usage_count = row
        return StickerService._attach_usage_fields(sticker, usage_count)

    @staticmethod
    def create_system_sticker(db: Session, sticker_in: StickerCreate) -> Sticker:
        sticker = Sticker(
            owner_user_id=None,
            name=sticker_in.name.strip(),
            image_url=sticker_in.image_url.strip(),
            public_id=StickerService._normalize_public_id(
                sticker_in.name,
                sticker_in.public_id,
            ),
            category=(sticker_in.category or "General").strip() or "General",
            is_ai_generated=bool(sticker_in.is_ai_generated),
            has_transparent_background=bool(sticker_in.has_transparent_background),
        )
        db.add(sticker)
        db.commit()
        db.refresh(sticker)
        return StickerService._attach_usage_fields(sticker, 0)

    @staticmethod
    def update_system_sticker(
        db: Session,
        sticker_id: int,
        sticker_in: StickerUpdate,
    ) -> Sticker:
        sticker = BaseService.get_or_404(
            db,
            Sticker,
            sticker_id,
            "System sticker not found",
        )
        if sticker.owner_user_id is not None:
            raise HTTPException(status_code=404, detail="System sticker not found")

        sticker.name = sticker_in.name.strip()
        sticker.image_url = sticker_in.image_url.strip()
        sticker.category = (sticker_in.category or "General").strip() or "General"
        sticker.is_ai_generated = bool(sticker_in.is_ai_generated)
        sticker.has_transparent_background = bool(sticker_in.has_transparent_background)
        sticker.public_id = StickerService._normalize_public_id(
            sticker.name,
            sticker_in.public_id or sticker.public_id,
        )

        db.commit()
        db.refresh(sticker)
        usage_count = (
            db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == sticker.id)
            .scalar()
            or 0
        )
        return StickerService._attach_usage_fields(sticker, usage_count)

    @staticmethod
    def delete_system_sticker(db: Session, sticker_id: int) -> dict:
        sticker = BaseService.get_or_404(
            db,
            Sticker,
            sticker_id,
            "System sticker not found",
        )
        if sticker.owner_user_id is not None:
            raise HTTPException(status_code=404, detail="System sticker not found")

        usage_count = (
            db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == sticker.id)
            .scalar()
            or 0
        )
        if usage_count > 0:
            raise HTTPException(
                status_code=400,
                detail="Không thể xóa sticker đã được người dùng sử dụng trong thiết kế",
            )

        db.delete(sticker)
        db.commit()
        return {"message": "Xóa sticker thành công"}
