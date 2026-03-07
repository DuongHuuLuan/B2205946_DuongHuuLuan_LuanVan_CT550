import json
from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import Conversation, Message, NotificationOutbox, User, UserDevice
from app.models.message import MessageType
from app.models.push_notification import NotificationOutboxStatus
from app.services.base import BaseService


class PushNotificationService(BaseService):
    @staticmethod
    def list_user_devices(db: Session, current_user: User) -> List[UserDevice]:
        return (
            db.query(UserDevice)
            .filter(UserDevice.user_id == current_user.id)
            .order_by(UserDevice.id.desc())
            .all()
        )

    @staticmethod
    def upsert_user_device(
        db: Session,
        current_user: User,
        platform,
        push_token: str,
        device_id: Optional[str] = None,
    ) -> UserDevice:
        token = (push_token or "").strip()
        if not token:
            raise HTTPException(status_code=400, detail="push_token không được rỗng")

        device = db.query(UserDevice).filter(UserDevice.push_token == token).first()
        if device:
            device.user_id = current_user.id
            device.platform = platform
            device.device_id = device_id
            device.is_active = True
            device.last_seen_at = datetime.utcnow()
            db.commit()
            db.refresh(device)
            return device

        if device_id:
            same_device = (
                db.query(UserDevice)
                .filter(
                    UserDevice.user_id == current_user.id,
                    UserDevice.device_id == device_id,
                )
                .first()
            )
            if same_device:
                same_device.platform = platform
                same_device.push_token = token
                same_device.is_active = True
                same_device.last_seen_at = datetime.utcnow()
                db.commit()
                db.refresh(same_device)
                return same_device

        device = UserDevice(
            user_id=current_user.id,
            platform=platform,
            device_id=device_id,
            push_token=token,
            is_active=True,
            last_seen_at=datetime.utcnow(),
        )
        db.add(device)
        db.commit()
        db.refresh(device)
        return device

    @staticmethod
    def deactivate_user_device(db: Session, current_user: User, push_token: str) -> bool:
        token = (push_token or "").strip()
        if not token:
            raise HTTPException(status_code=400, detail="push_token không hợp lệ")

        device = (
            db.query(UserDevice)
            .filter(
                UserDevice.user_id == current_user.id,
                UserDevice.push_token == token,
            )
            .first()
        )
        if not device:
            return False

        device.is_active = False
        device.last_seen_at = datetime.utcnow()
        db.commit()
        return True

    @staticmethod
    def deactivate_device_by_token(db: Session, push_token: str, commit: bool = True) -> None:
        token = (push_token or "").strip()
        if not token:
            return

        device = db.query(UserDevice).filter(UserDevice.push_token == token).first()
        if not device:
            return

        device.is_active = False
        device.last_seen_at = datetime.utcnow()
        if commit:
            db.commit()

    @staticmethod
    def _build_message_preview(message: Message) -> str:
        if message.content and message.content.strip():
            return message.content.strip()[:180]

        if message.type == MessageType.IMAGE:
            return "Bạn vừa nhận ảnh mới"
        if message.type == MessageType.FILE:
            return "Bạn vừa nhận tệp mới"
        return "Bạn có tin nhắn mới"

    @staticmethod
    def enqueue_chat_notification(
        db: Session,
        conversation: Conversation,
        message: Message,
        receiver_user_id: int,
    ) -> Optional[NotificationOutbox]:
        has_active_device = (
            db.query(UserDevice.id)
            .filter(
                UserDevice.user_id == receiver_user_id,
                UserDevice.is_active.is_(True),
            )
            .first()
        )
        if not has_active_device:
            return None

        dedupe_key = f"chat_message_{message.id}_to_{receiver_user_id}"
        existed = (
            db.query(NotificationOutbox.id)
            .filter(NotificationOutbox.dedupe_key == dedupe_key)
            .first()
        )
        if existed:
            return None

        body = PushNotificationService._build_message_preview(message)
        payload = {
            "title": "Tin nhắn mới",
            "body": body,
            "data": {
                "event": "chat.message.created",
                "conversation_id": conversation.id,
                "message_id": message.id,
                "sender_id": message.user_id,
                "receiver_id": receiver_user_id,
                "type": message.type.value,
            },
        }
        payload_str = json.dumps(payload, ensure_ascii=False)

        outbox = NotificationOutbox(
            user_id=receiver_user_id,
            conversation_id=conversation.id,
            message_id=message.id,
            event_type="chat.message.created",
            payload=payload_str,
            dedupe_key=dedupe_key,
            status=NotificationOutboxStatus.PENDING,
            retry_count=0,
            max_retry=settings.PUSH_OUTBOX_MAX_RETRY,
        )
        db.add(outbox)
        return outbox
