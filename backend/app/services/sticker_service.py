import io
import math
import os
import re
import uuid
from datetime import datetime
from typing import Dict, List, Optional

import cloudinary.uploader
from fastapi import HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models import DesignLayer, Sticker, User
from app.schemas.sticker import AiStickerGenerateIn, StickerCreate, StickerUpdate
from app.services.base import BaseService
from app.services.openai_audio_service import OpenAIAudioService
from app.services.openai_image_service import OpenAIImageService


class StickerService(BaseService):
    SUPPORTED_VOICE_AUDIO_EXTENSIONS = {
        ".mp3",
        ".mp4",
        ".mpeg",
        ".mpga",
        ".m4a",
        ".wav",
        ".webm",
    }

    @staticmethod
    def _normalize_generated_name(name: Optional[str], prompt: str) -> str:
        normalized_name = (name or "").strip()
        if normalized_name:
            return normalized_name[:255]

        compact_prompt = re.sub(r"\s+", " ", (prompt or "")).strip()
        if not compact_prompt:
            return f"AI Sticker {uuid.uuid4().hex[:8]}"
        if len(compact_prompt) > 80:
            compact_prompt = f"{compact_prompt[:77].rstrip()}..."
        return compact_prompt

    @staticmethod
    def _validate_voice_audio(
        filename: str,
        content_type: Optional[str],
        audio_bytes: bytes,
    ) -> str:
        if not audio_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File audio không được để trống",
            )

        max_file_mb = max(int(settings.AI_STICKER_VOICE_MAX_FILE_MB or 0), 1)
        max_bytes = max_file_mb * 1024 * 1024
        if len(audio_bytes) > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File audio vượt quá giới hạn {max_file_mb}MB",
            )

        normalized_filename = (filename or "").strip() or "ai-sticker-voice.m4a"
        extension = os.path.splitext(normalized_filename)[1].lower()
        normalized_content_type = (content_type or "").strip().lower()
        if extension and extension not in StickerService.SUPPORTED_VOICE_AUDIO_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Định dạng audio chưa được hỗ trợ",
            )
        if not extension and normalized_content_type and not normalized_content_type.startswith("audio/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File gửi lên không phải audio hợp lệ",
            )
        return normalized_filename

    @staticmethod
    def transcribe_voice_prompt(
        filename: str,
        content_type: Optional[str],
        audio_bytes: bytes,
    ) -> str:
        normalized_filename = StickerService._validate_voice_audio(
            filename=filename,
            content_type=content_type,
            audio_bytes=audio_bytes,
        )
        prompt = OpenAIAudioService.transcribe_audio(
            audio_bytes=audio_bytes,
            filename=normalized_filename,
            content_type=content_type,
        )
        normalized_prompt = re.sub(r"\s+", " ", prompt).strip()
        if len(normalized_prompt) < 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không nghe rõ mô tả sticker, Vui lòng thử lại",
            )
        return normalized_prompt[:500]

    @staticmethod
    def _build_ai_prompt(sticker_in: AiStickerGenerateIn) -> str:
        # Quy định các nguyên tắc chung cho prompt tạo sticker AI để đảm bảo chất lượng và tính nhất quán của hình ảnh được tạo ra. Các nguyên tắc này bao gồm: Hình minh họa rõ ràng với một chủ thể chính ở trung tâm, sử dụng đường viền đậm, hình dạng đơn giản dễ nhận biết và độ tương phản cao. Không bao gồm bất kỳ văn bản, watermark, logo, khung hoặc đối tượng thừa nào trong hình ảnh. Nếu người dùng yêu cầu tách nền, sử dụng nền trong suốt; nếu không, giữ nền tối giản và không gây chú ý. Cho phép người dùng tùy chọn thêm phong cách hình ảnh và bảng màu chủ đạo để cá nhân hóa sticker, nhưng vẫn đảm bảo rằng chủ thể chính là yếu tố nổi bật nhất trong hình ảnh. Cuối cùng, mô tả rõ ràng chủ thể của sticker dựa trên prompt do người dùng cung cấp.
        parts = [
            "Create one clean sticker illustration with a single centered subject.",
            "Use a bold outline, simple readable shapes, and strong contrast.",
            "Do not include any text, watermark, logo, frame, or extra objects.",
        ]

        if sticker_in.remove_background:
            parts.append("Use a transparent background.")
        else:
            parts.append("Keep the background minimal and unobtrusive.")

        if sticker_in.style and sticker_in.style.strip():
            parts.append(f"Visual style: {sticker_in.style.strip()}.")

        if sticker_in.dominant_color and sticker_in.dominant_color.strip():
            parts.append(f"Dominant color palette: {sticker_in.dominant_color.strip()}.")

        parts.append(f"Subject: {sticker_in.prompt.strip()}.")
        return " ".join(parts)


    @staticmethod
    def _upload_generated_image(image_bytes: bytes, name: str) -> dict:
        upload_stream = io.BytesIO(image_bytes)
        upload_stream.name = f"{StickerService._normalize_public_id(name)}.png"
        try:
            return cloudinary.uploader.upload(
                upload_stream,
                folder=settings.AI_STICKER_CLOUDINARY_FOLDER,
                resource_type="image",
                format="png",
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Không thể tải ảnh sticker lên Cloudinary: {exc}",
            ) from exc

    @staticmethod
    def generate_ai_sticker(
        db: Session,
        user_id: int,
        sticker_in: AiStickerGenerateIn,
    ) -> Sticker:
        prompt = (sticker_in.prompt or "").strip()
        if not prompt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Prompt không được để trống",
            )

        sticker_name = StickerService._normalize_generated_name(sticker_in.name, prompt)
        ai_prompt = StickerService._build_ai_prompt(sticker_in)
        generated = OpenAIImageService.generate_sticker(
            prompt=ai_prompt,
            remove_background=sticker_in.remove_background,
        )
        upload_result = StickerService._upload_generated_image(
            image_bytes=generated.image_bytes,
            name=sticker_name,
        )
        image_url = upload_result.get("secure_url")
        public_id = upload_result.get("public_id")
        if not image_url or not public_id:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Cloudinary không trả về thông tin hợp lệ",
            )

        sticker = Sticker(
            owner_user_id=user_id,
            name=sticker_name,
            image_url=image_url,
            public_id=public_id,
            category="AI Generated",
            is_ai_generated=True,
            has_transparent_background=generated.has_transparent_background,
        )
        db.add(sticker)

        try:
            db.commit()
        except Exception as exc:
            db.rollback()
            if public_id:
                cloudinary.uploader.destroy(public_id)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể lưu sticker AI vào hệ thống",
            ) from exc

        db.refresh(sticker)
        return sticker

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
    def _validate_admin_scope(scope: Optional[str]) -> str:
        normalized = (scope or "system").strip().lower()
        if normalized not in {"system", "user"}:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Phạm vi sticker không hợp lệ",
            )
        return normalized

    @staticmethod
    def _attach_admin_fields(sticker: Sticker, usage_count: int) -> Sticker:
        normalized_usage = int(usage_count or 0)
        owner = getattr(sticker, "owner", None)
        is_system_sticker = sticker.owner_user_id is None

        setattr(sticker, "usage_count", normalized_usage)
        setattr(sticker, "owner_username", getattr(owner, "username", None))
        setattr(sticker, "owner_email", getattr(owner, "email", None))
        setattr(sticker, "can_edit", is_system_sticker)
        setattr(sticker, "can_delete", is_system_sticker and normalized_usage == 0)
        return sticker

    @staticmethod
    def list_admin_stickers(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        category: Optional[str] = None,
        scope: Optional[str] = "system",
    ) -> dict:
        normalized_scope = StickerService._validate_admin_scope(scope)
        base_query = db.query(Sticker).options(joinedload(Sticker.owner))

        if normalized_scope == "system":
            base_query = base_query.filter(Sticker.owner_user_id.is_(None))
        else:
            base_query = base_query.filter(Sticker.owner_user_id.isnot(None))

        if keyword:
            like_pattern = f"%{keyword.strip()}%"
            base_query = base_query.outerjoin(User, Sticker.owner_user_id == User.id)
            base_query = base_query.filter(
                or_(
                    Sticker.name.ilike(like_pattern),
                    Sticker.category.ilike(like_pattern),
                    Sticker.image_url.ilike(like_pattern),
                    User.username.ilike(like_pattern),
                    User.email.ilike(like_pattern),
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
        stickers = (
            base_query.order_by(Sticker.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        sticker_ids = [sticker.id for sticker in stickers]
        usage_rows = (
            db.query(
                DesignLayer.sticker_id,
                func.count(DesignLayer.id).label("usage_count"),
            )
            .filter(DesignLayer.sticker_id.in_(sticker_ids))
            .group_by(DesignLayer.sticker_id)
            .all()
            if sticker_ids
            else []
        )
        usage_map = {
            sticker_id: int(usage_count or 0)
            for sticker_id, usage_count in usage_rows
        }

        items = [
            StickerService._attach_admin_fields(
                sticker,
                usage_map.get(sticker.id, 0),
            )
            for sticker in stickers
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
        sticker = (
            db.query(Sticker)
            .options(joinedload(Sticker.owner))
            .filter(
                Sticker.id == sticker_id,
                Sticker.owner_user_id.is_(None),
            )
            .first()
        )
        if not sticker:
            raise HTTPException(status_code=404, detail="System sticker not found")

        usage_count = (
            db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == sticker.id)
            .scalar()
            or 0
        )
        return StickerService._attach_admin_fields(sticker, usage_count)

    @staticmethod
    def get_admin_sticker(db: Session, sticker_id: int) -> Sticker:
        sticker = (
            db.query(Sticker)
            .options(joinedload(Sticker.owner))
            .filter(Sticker.id == sticker_id)
            .first()
        )
        if not sticker:
            raise HTTPException(status_code=404, detail="Sticker not found")

        usage_count = (
            db.query(func.count(DesignLayer.id))
            .filter(DesignLayer.sticker_id == sticker.id)
            .scalar()
            or 0
        )
        return StickerService._attach_admin_fields(sticker, usage_count)

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
        return StickerService._attach_admin_fields(sticker, 0)

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
        return StickerService._attach_admin_fields(sticker, usage_count)

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
