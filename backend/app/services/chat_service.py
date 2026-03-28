import json
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import cloudinary.uploader
from fastapi import HTTPException, UploadFile
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models import Conversation, Message, MessageMedia, User
from app.models.conversation import ConversationStatus
from app.models.message import MessageType
from app.models.message_media import MessageMediaType
from app.models.user import UserRole
from app.services.base import BaseService
from app.services.chat_ws_service import chat_ws_manager
from app.services.push_notification_service import PushNotificationService


class ChatService(BaseService):
    RECALLED_MESSAGE_PLACEHOLDER = "Tin nhắn đã được thu hồi"

    @staticmethod
    def _assert_member(conversation: Conversation, user: User) -> None:
        if user.id not in (conversation.user_id, conversation.admin_id):
            raise HTTPException(status_code=403, detail="You are not a member of this conversation")

    @staticmethod
    def _pick_default_admin(db: Session) -> User:
        admin = db.query(User).filter(User.role == UserRole.ADMIN).order_by(User.id.asc()).first()
        if not admin:
            raise HTTPException(status_code=400, detail="No admin account is available for chat")
        return admin

    @staticmethod
    def _get_actor_read_field_name(current_user: User) -> str:
        if current_user.role == UserRole.ADMIN:
            return "last_read_admin_message_id"
        return "last_read_user_message_id"

    @staticmethod
    def _get_actor_last_read_message_id(conversation: Conversation, current_user: User) -> Optional[int]:
        return getattr(conversation, ChatService._get_actor_read_field_name(current_user))

    @staticmethod
    def _serialize_conversation(
        conversation: Conversation,
        current_user: User,
        unread_count: int = 0,
    ) -> dict:
        return {
            "id": conversation.id,
            "user_id": conversation.user_id,
            "admin_id": conversation.admin_id,
            "user": ChatService._serialize_user_summary(conversation.user),
            "status": conversation.status,
            "last_message_id": conversation.last_message_id,
            "last_read_user_message_id": conversation.last_read_user_message_id,
            "last_read_admin_message_id": conversation.last_read_admin_message_id,
            "last_read_message_id": ChatService._get_actor_last_read_message_id(conversation, current_user),
            "unread_count": unread_count,
            "last_message_at": conversation.last_message_at,
            "created_at": conversation.created_at,
            "updated_at": conversation.updated_at,
        }

    @staticmethod
    def _serialize_user_summary(user: Optional[User]) -> Optional[dict]:
        if not user:
            return None

        profile = user.profile
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "profile": {
                "name": profile.name if profile else None,
                "phone": profile.phone if profile else None,
                "avatar": profile.avatar if profile else None,
            } if profile else None,
        }

    @staticmethod
    def get_conversation_with_user(db: Session, conversation_id: int) -> Optional[Conversation]:
        return (
            db.query(Conversation)
            .options(joinedload(Conversation.user).joinedload(User.profile))
            .filter(Conversation.id == conversation_id)
            .first()
        )

    @staticmethod
    def _get_unread_counts(
        db: Session,
        conversations: List[Conversation],
        current_user: User,
    ) -> dict[int, int]:
        if not conversations:
            return {}

        conversation_ids = [conversation.id for conversation in conversations]
        read_column = (
            Conversation.last_read_admin_message_id
            if current_user.role == UserRole.ADMIN
            else Conversation.last_read_user_message_id
        )

        rows = (
            db.query(
                Message.conversation_id,
                func.count(Message.id).label("unread_count"),
            )
            .join(Conversation, Conversation.id == Message.conversation_id)
            .filter(
                Message.conversation_id.in_(conversation_ids),
                Message.deleted_at.is_(None),
                Message.user_id != current_user.id,
                Message.id > func.coalesce(read_column, 0),
            )
            .group_by(Message.conversation_id)
            .all()
        )
        return {row.conversation_id: row.unread_count for row in rows}

    @staticmethod
    def build_conversation_out(
        db: Session,
        conversation: Conversation,
        current_user: User,
    ) -> dict:
        unread_count = ChatService._get_unread_counts(db, [conversation], current_user).get(conversation.id, 0)
        return ChatService._serialize_conversation(conversation, current_user, unread_count)

    @staticmethod
    def _serialize_message_media(media: MessageMedia) -> dict:
        return {
            "id": media.id,
            "path": media.path,
            "media_type": media.media_type,
            "created_at": media.created_at,
        }

    @staticmethod
    def _parse_message_metadata(message: Message) -> Dict[str, Any]:
        raw = getattr(message, "metadata_json", None)
        if not raw:
            return {}

        if isinstance(raw, dict):
            return raw

        if isinstance(raw, str):
            try:
                parsed = json.loads(raw)
            except (TypeError, ValueError, json.JSONDecodeError):
                return {}
            return parsed if isinstance(parsed, dict) else {}

        return {}

    @staticmethod
    def serialize_message(message: Message) -> dict:
        is_recalled = message.deleted_at is not None
        metadata = ChatService._parse_message_metadata(message)
        sender_role = metadata.get("sender_role")
        if sender_role is not None:
            sender_role = str(sender_role).strip().lower() or None

        payload = metadata.get("payload")
        if not isinstance(payload, dict):
            payload = None

        return {
            "id": message.id,
            "conversation_id": message.conversation_id,
            "user_id": message.user_id,
            "type": message.type,
            "client_msg_id": message.client_msg_id,
            "sender_role": sender_role,
            "content": (
                ChatService.RECALLED_MESSAGE_PLACEHOLDER
                if is_recalled
                else message.content
            ),
            "payload": None if is_recalled else payload,
            "created_at": message.created_at,
            "media_items": (
                []
                if is_recalled
                else [
                    ChatService._serialize_message_media(media)
                    for media in (message.media_items or [])
                ]
            ),
            "is_recalled": is_recalled,
            "recalled_at": message.deleted_at,
        }

    @staticmethod
    def _guess_media_type_from_upload(file: UploadFile) -> MessageMediaType:
        content_type = (file.content_type or "").lower()
        if content_type.startswith("image/"):
            return MessageMediaType.IMAGE
        if content_type.startswith("video/"):
            return MessageMediaType.VIDEO
        if content_type.startswith("audio/"):
            return MessageMediaType.AUDIO
        return MessageMediaType.FILE

    @staticmethod
    def get_or_create_conversation(db: Session, user_id: int, admin_id: int) -> Conversation:
        user = ChatService.get_or_404(db, User, user_id, "User not found")
        admin = ChatService.get_or_404(db, User, admin_id, "Admin not found")

        if user.role != UserRole.USER:
            raise HTTPException(status_code=400, detail="Invalid user_id")
        if admin.role != UserRole.ADMIN:
            raise HTTPException(status_code=400, detail="Invalid admin_id")

        conversation = db.query(Conversation).filter(
            Conversation.user_id == user_id,
            Conversation.admin_id == admin_id,
        ).first()
        if conversation:
            return conversation

        conversation = Conversation(user_id=user_id, admin_id=admin_id)
        db.add(conversation)
        db.commit()
        db.refresh(conversation)
        return conversation

    @staticmethod
    def create_or_get_for_actor(
        db: Session,
        current_user: User,
        user_id: Optional[int] = None,
        admin_id: Optional[int] = None,
    ) -> Conversation:
        if current_user.role == UserRole.ADMIN:
            if user_id is None:
                raise HTTPException(status_code=400, detail="Admin must provide user_id to open chat")
            return ChatService.get_or_create_conversation(db=db, user_id=user_id, admin_id=current_user.id)

        if current_user.role == UserRole.USER:
            target_admin_id = admin_id
            if target_admin_id is None:
                target_admin_id = ChatService._pick_default_admin(db).id
            return ChatService.get_or_create_conversation(
                db=db,
                user_id=current_user.id,
                admin_id=target_admin_id,
            )

        raise HTTPException(status_code=403, detail="You do not have permission to create a conversation")

    @staticmethod
    def list_conversations(db: Session, current_user: User) -> List[dict]:
        query = db.query(Conversation).options(
            joinedload(Conversation.user).joinedload(User.profile)
        )
        if current_user.role == UserRole.ADMIN:
            query = query.filter(Conversation.admin_id == current_user.id)
        else:
            query = query.filter(Conversation.user_id == current_user.id)

        conversations = query.order_by(
            func.coalesce(Conversation.last_message_at, Conversation.created_at).desc()
        ).all()
        unread_map = ChatService._get_unread_counts(db, conversations, current_user)
        return [
            ChatService._serialize_conversation(
                conversation=conversation,
                current_user=current_user,
                unread_count=unread_map.get(conversation.id, 0),
            )
            for conversation in conversations
        ]

    @staticmethod
    def list_messages(
        db: Session,
        conversation_id: int,
        current_user: User,
        cursor: Optional[int] = None,
        limit: int = 20,
    ) -> Tuple[List[Message], Optional[int]]:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        ChatService._assert_member(conversation, current_user)

        limit = max(1, min(limit, 50))
        query = db.query(Message).options(joinedload(Message.media_items)).filter(
            Message.conversation_id == conversation_id,
        )
        if cursor:
            query = query.filter(Message.id < cursor)

        rows = query.order_by(Message.id.desc()).limit(limit).all()
        next_cursor = rows[-1].id if len(rows) == limit else None
        rows.reverse()
        return rows, next_cursor

    @staticmethod
    def send_message_with_uploads(
        db: Session,
        conversation_id: int,
        current_user: User,
        files: Optional[List[UploadFile]] = None,
        content: Optional[str] = None,
        client_msg_id: Optional[str] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        ChatService._assert_member(conversation, current_user)

        cleaned_content = (content or "").strip()
        if not files and not cleaned_content:
            raise HTTPException(status_code=400, detail="Message content cannot be empty")

        if client_msg_id:
            existed = db.query(Message).options(joinedload(Message.media_items)).filter(
                Message.user_id == current_user.id,
                Message.client_msg_id == client_msg_id,
            ).first()
            if existed:
                return existed

        uploaded_items = []
        uploaded_public_ids: List[str] = []
        try:
            for file in files or []:
                upload_result = cloudinary.uploader.upload(
                    file.file,
                    folder="helmet_shop/chat",
                    resource_type="auto",
                )
                uploaded_items.append(
                    {
                        "path": upload_result["secure_url"],
                        "media_type": ChatService._guess_media_type_from_upload(file),
                    }
                )
                if upload_result.get("public_id"):
                    uploaded_public_ids.append(upload_result["public_id"])

            if uploaded_items:
                if all(item["media_type"] == MessageMediaType.IMAGE for item in uploaded_items):
                    message_type = MessageType.IMAGE
                else:
                    message_type = MessageType.FILE
            else:
                message_type = MessageType.TEXT

            message = Message(
                conversation_id=conversation_id,
                user_id=current_user.id,
                type=message_type,
                content=cleaned_content if cleaned_content else None,
                client_msg_id=client_msg_id,
            )
            db.add(message)
            db.flush()

            for item in uploaded_items:
                db.add(
                    MessageMedia(
                        message_id=message.id,
                        path=item["path"],
                        media_type=item["media_type"],
                    )
                )

            conversation.last_message_id = message.id
            conversation.last_message_at = datetime.utcnow()

            receiver_user_id = (
                conversation.admin_id
                if current_user.id == conversation.user_id
                else conversation.user_id
            )
            if not chat_ws_manager.has_user_connection(
                conversation_id=conversation.id,
                user_id=receiver_user_id,
            ):
                PushNotificationService.enqueue_chat_notification(
                    db=db,
                    conversation=conversation,
                    message=message,
                    receiver_user_id=receiver_user_id,
                )

            db.commit()

            return db.query(Message).options(joinedload(Message.media_items)).filter(
                Message.id == message.id
            ).first()
        except Exception:
            db.rollback()
            for public_id in uploaded_public_ids:
                try:
                    cloudinary.uploader.destroy(public_id, invalidate=True)
                except Exception:
                    pass
            raise

    @staticmethod
    def _create_automated_message(
        db: Session,
        conversation: Conversation,
        *,
        sender_role: str,
        actor_user_id: Optional[int],
        content: str,
        payload: Optional[Dict[str, Any]] = None,
        reply_to_message_id: Optional[int] = None,
    ) -> Message:
        cleaned_content = (content or "").strip()
        if not cleaned_content and payload is None:
            raise HTTPException(status_code=400, detail="Tin nhắn hệ thống không được để trống")

        metadata: Dict[str, Any] = {
            "sender_role": sender_role,
        }
        if isinstance(payload, dict) and payload:
            metadata["payload"] = payload
        if reply_to_message_id is not None:
            metadata["reply_to_message_id"] = reply_to_message_id

        try:
            message = Message(
                conversation_id=conversation.id,
                user_id=actor_user_id or conversation.admin_id,
                type=MessageType.SYSTEM,
                content=cleaned_content or None,
                metadata_json=json.dumps(metadata, ensure_ascii=False),
            )
            db.add(message)
            db.flush()

            conversation.last_message_id = message.id
            conversation.last_message_at = datetime.utcnow()

            if not chat_ws_manager.has_user_connection(
                conversation_id=conversation.id,
                user_id=conversation.user_id,
            ):
                PushNotificationService.enqueue_chat_notification(
                    db=db,
                    conversation=conversation,
                    message=message,
                    receiver_user_id=conversation.user_id,
                )

            db.commit()

            return (
                db.query(Message)
                .options(joinedload(Message.media_items))
                .filter(Message.id == message.id)
                .first()
            )
        except Exception:
            db.rollback()
            raise

    @staticmethod
    def create_bot_message(
        db: Session,
        conversation_id: int,
        content: str,
        payload: Optional[Dict[str, Any]] = None,
        reply_to_message_id: Optional[int] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        return ChatService._create_automated_message(
            db=db,
            conversation=conversation,
            sender_role="bot",
            actor_user_id=conversation.admin_id,
            content=content,
            payload=payload,
            reply_to_message_id=reply_to_message_id,
        )

    @staticmethod
    def create_system_message(
        db: Session,
        conversation_id: int,
        content: str,
        payload: Optional[Dict[str, Any]] = None,
        actor_user_id: Optional[int] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        return ChatService._create_automated_message(
            db=db,
            conversation=conversation,
            sender_role="system",
            actor_user_id=actor_user_id or conversation.admin_id,
            content=content,
            payload=payload,
        )

    @staticmethod
    def activate_handoff(
        db: Session,
        conversation_id: int,
        content: str,
        notice_message: str,
        reply_to_message_id: Optional[int] = None,
    ) -> Message:
        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        conversation.status = ConversationStatus.CLOSED
        return ChatService._create_automated_message(
            db=db,
            conversation=conversation,
            sender_role="bot",
            actor_user_id=conversation.admin_id,
            content=content,
            payload={
                "kind": "handoff_notice",
                "notice_code": "human_handoff_requested",
                "notice_message": notice_message,
            },
            reply_to_message_id=reply_to_message_id,
        )

    @staticmethod
    def claim_handoff(
        db: Session,
        conversation_id: int,
        current_user: User,
    ) -> Message:
        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        ChatService._assert_member(conversation, current_user)
        if current_user.role != UserRole.ADMIN or current_user.id != conversation.admin_id:
            raise HTTPException(status_code=403, detail="Bạn không có quyền tiếp nhận cuộc hội thoại này")
        if conversation.status != ConversationStatus.CLOSED:
            raise HTTPException(status_code=400, detail="Cuộc hội thoại này chưa ở trạng thái cần tiếp nhận")

        return ChatService._create_automated_message(
            db=db,
            conversation=conversation,
            sender_role="system",
            actor_user_id=current_user.id,
            content="Tư vấn viên đã tham gia cuộc trò chuyện và sẽ hỗ trợ bạn trực tiếp.",
            payload={
                "kind": "handoff_notice",
                "notice_code": "human_handoff_claimed",
                "notice_message": "Tư vấn viên đã tiếp nhận cuộc trò chuyện này.",
            },
        )

    @staticmethod
    def resume_chatbot(
        db: Session,
        conversation_id: int,
        current_user: User,
    ) -> Message:
        conversation = ChatService.get_or_404(
            db,
            Conversation,
            conversation_id,
            "Conversation not found",
        )
        ChatService._assert_member(conversation, current_user)
        if current_user.role != UserRole.ADMIN or current_user.id != conversation.admin_id:
            raise HTTPException(status_code=403, detail="Bạn không có quyền bật lại trợ lý AI cho cuộc hội thoại này")

        conversation.status = ConversationStatus.OPEN
        return ChatService._create_automated_message(
            db=db,
            conversation=conversation,
            sender_role="system",
            actor_user_id=current_user.id,
            content="Trợ lý AI đã được bật lại. Bạn có thể tiếp tục hỏi để được hỗ trợ nhanh hơn.",
            payload={
                "kind": "handoff_notice",
                "notice_code": "bot_resumed",
                "notice_message": "Trợ lý AI đã được kích hoạt lại cho cuộc trò chuyện này.",
            },
        )

    @staticmethod
    def recall_message(
        db: Session,
        conversation_id: int,
        message_id: int,
        current_user: User,
    ) -> Message:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        ChatService._assert_member(conversation, current_user)

        message = (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(
                Message.id == message_id,
                Message.conversation_id == conversation_id,
            )
            .first()
        )
        if not message:
            raise HTTPException(status_code=404, detail="Message not found")
        if message.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only recall your own messages")

        if message.deleted_at is None:
            message.deleted_at = datetime.utcnow()
            message.updated_at = datetime.utcnow()
            db.commit()
        else:
            db.rollback()

        return (
            db.query(Message)
            .options(joinedload(Message.media_items))
            .filter(Message.id == message.id)
            .first()
        )

    @staticmethod
    def mark_as_read(
        db: Session,
        conversation_id: int,
        current_user: User,
        message_id: Optional[int] = None,
    ) -> dict:
        conversation = ChatService.get_or_404(db, Conversation, conversation_id, "Conversation not found")
        ChatService._assert_member(conversation, current_user)

        latest_incoming_message_query = db.query(Message.id).filter(
            Message.conversation_id == conversation_id,
            Message.deleted_at.is_(None),
            Message.user_id != current_user.id,
        )
        if message_id is not None:
            latest_incoming_message_query = latest_incoming_message_query.filter(Message.id <= message_id)

        latest_incoming_message = latest_incoming_message_query.order_by(Message.id.desc()).first()
        read_field_name = ChatService._get_actor_read_field_name(current_user)
        current_read_message_id = getattr(conversation, read_field_name)
        next_read_message_id = current_read_message_id
        changed = False

        if latest_incoming_message:
            latest_incoming_message_id = latest_incoming_message[0]
            if current_read_message_id is None or latest_incoming_message_id > current_read_message_id:
                setattr(conversation, read_field_name, latest_incoming_message_id)
                db.commit()
                db.refresh(conversation)
                next_read_message_id = latest_incoming_message_id
                changed = True

        unread_count = ChatService._get_unread_counts(db, [conversation], current_user).get(conversation.id, 0)
        return {
            "conversation_id": conversation.id,
            "last_read_message_id": next_read_message_id,
            "unread_count": unread_count,
            "changed": changed,
        }
