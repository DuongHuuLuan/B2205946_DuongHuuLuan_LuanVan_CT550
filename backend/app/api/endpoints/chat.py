from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, Body, Depends, File, Form, HTTPException, Query, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.encoders import jsonable_encoder
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.api.deps import require_user
from app.core.config import settings
from app.db.session import SessionLocal, get_db
from app.models import Conversation, User
from app.models.user import UserRole
from app.schemas.chat import (
    ConversationCreateIn,
    ConversationOut,
    ConversationReadIn,
    ConversationReadOut,
    MessageListOut,
    MessageOut,
)
from app.services.chat_service import ChatService
from app.services.chat_ws_service import chat_ws_manager


router = APIRouter(prefix="/chat", tags=["Chat"])


def _normalize_ws_token(token: str) -> str:
    raw = token.strip()
    if raw.lower().startswith("bearer "):
        return raw.split(" ", 1)[1].strip()
    return raw


def _get_ws_user_from_token(db: Session, token: str) -> Optional[User]:
    normalized_token = _normalize_ws_token(token)
    try:
        payload = jwt.decode(normalized_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            return None
    except JWTError:
        return None

    try:
        parsed_user_id = int(user_id)
    except (TypeError, ValueError):
        return None

    return db.query(User).filter(User.id == parsed_user_id).first()


def _message_new_payload(conversation_id: int, message_out: MessageOut) -> Dict[str, Any]:
    return {
        "event": "message:new",
        "conversation_id": conversation_id,
        "data": jsonable_encoder(message_out),
    }


def _message_read_payload(
    conversation_id: int,
    user_id: int,
    read_out: ConversationReadOut,
) -> Dict[str, Any]:
    return {
        "event": "message:read",
        "conversation_id": conversation_id,
        "user_id": user_id,
        "data": jsonable_encoder(read_out),
    }


def _create_message(
    conversation_id: int,
    user_id: int,
    files: Optional[List[UploadFile]],
    content: Optional[str],
    client_msg_id: Optional[str],
) -> MessageOut:
    db = SessionLocal()
    try:
        current_user = db.query(User).filter(User.id == user_id).first()
        if not current_user:
            raise HTTPException(status_code=401, detail="Invalid user")

        message = ChatService.send_message_with_uploads(
            db=db,
            conversation_id=conversation_id,
            current_user=current_user,
            files=files,
            content=content,
            client_msg_id=client_msg_id,
        )
        return MessageOut.model_validate(message)
    finally:
        db.close()


def _mark_conversation_read(
    conversation_id: int,
    user_id: int,
    message_id: Optional[int] = None,
) -> ConversationReadOut:
    db = SessionLocal()
    try:
        current_user = db.query(User).filter(User.id == user_id).first()
        if not current_user:
            raise HTTPException(status_code=401, detail="Invalid user")

        read_result = ChatService.mark_as_read(
            db=db,
            conversation_id=conversation_id,
            current_user=current_user,
            message_id=message_id,
        )
        return ConversationReadOut.model_validate(read_result)
    finally:
        db.close()


def _build_admin_conversation_snapshot(conversation_id: int) -> Optional[Tuple[int, Dict[str, Any]]]:
    db = SessionLocal()
    try:
        conversation = ChatService.get_conversation_with_user(db, conversation_id)
        if not conversation:
            return None

        admin = db.query(User).filter(User.id == conversation.admin_id).first()
        if not admin:
            return None

        conversation_out = ChatService.build_conversation_out(
            db=db,
            conversation=conversation,
            current_user=admin,
        )
        return conversation.admin_id, jsonable_encoder(conversation_out)
    finally:
        db.close()


def _build_admin_message_new_payload(
    conversation_id: int,
    message_out: MessageOut,
) -> Optional[Tuple[int, Dict[str, Any]]]:
    snapshot = _build_admin_conversation_snapshot(conversation_id)
    if not snapshot:
        return None

    admin_id, conversation_payload = snapshot
    return admin_id, {
        "event": "message:new",
        "conversation_id": conversation_id,
        "data": jsonable_encoder(message_out),
        "conversation": conversation_payload,
    }


def _build_admin_message_read_payload(
    conversation_id: int,
    user_id: int,
    read_out: ConversationReadOut,
) -> Optional[Tuple[int, Dict[str, Any]]]:
    snapshot = _build_admin_conversation_snapshot(conversation_id)
    if not snapshot:
        return None

    admin_id, conversation_payload = snapshot
    return admin_id, {
        "event": "message:read",
        "conversation_id": conversation_id,
        "user_id": user_id,
        "data": jsonable_encoder(read_out),
        "conversation": conversation_payload,
    }


async def _broadcast_admin_message_new(conversation_id: int, message_out: MessageOut) -> None:
    payload = await run_in_threadpool(
        _build_admin_message_new_payload,
        conversation_id,
        message_out,
    )
    if not payload:
        return

    admin_id, event_payload = payload
    await chat_ws_manager.broadcast_admin(admin_id=admin_id, payload=event_payload)


async def _broadcast_admin_message_read(
    conversation_id: int,
    user_id: int,
    read_out: ConversationReadOut,
) -> None:
    payload = await run_in_threadpool(
        _build_admin_message_read_payload,
        conversation_id,
        user_id,
        read_out,
    )
    if not payload:
        return

    admin_id, event_payload = payload
    await chat_ws_manager.broadcast_admin(admin_id=admin_id, payload=event_payload)


@router.get("/conversations", response_model=List[ConversationOut])
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return ChatService.list_conversations(db=db, current_user=current_user)


@router.post("/conversations", response_model=ConversationOut)
def create_or_get_conversation(
    payload: ConversationCreateIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    conversation = ChatService.create_or_get_for_actor(
        db=db,
        current_user=current_user,
        user_id=payload.user_id,
        admin_id=payload.admin_id,
    )
    return ChatService.build_conversation_out(db=db, conversation=conversation, current_user=current_user)


@router.get("/conversations/{conversation_id}/messages", response_model=MessageListOut)
def get_messages(
    conversation_id: int,
    cursor: Optional[int] = Query(default=None),
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    items, next_cursor = ChatService.list_messages(
        db=db,
        conversation_id=conversation_id,
        current_user=current_user,
        cursor=cursor,
        limit=limit,
    )
    return MessageListOut(items=items, next_cursor=next_cursor)


@router.post("/conversations/{conversation_id}/messages", response_model=MessageOut)
async def send_message_with_uploads(
    conversation_id: int,
    files: Optional[List[UploadFile]] = File(default=None),
    content: Optional[str] = Form(default=None),
    client_msg_id: Optional[str] = Form(default=None),
    current_user: User = Depends(require_user),
):
    message_out = await run_in_threadpool(
        _create_message,
        conversation_id,
        current_user.id,
        files,
        content,
        client_msg_id,
    )
    await chat_ws_manager.broadcast(
        conversation_id=conversation_id,
        payload=_message_new_payload(conversation_id=conversation_id, message_out=message_out),
    )
    await _broadcast_admin_message_new(conversation_id=conversation_id, message_out=message_out)
    return message_out


@router.post("/conversations/{conversation_id}/read", response_model=ConversationReadOut)
async def mark_conversation_read(
    conversation_id: int,
    payload: Optional[ConversationReadIn] = Body(default=None),
    current_user: User = Depends(require_user),
):
    read_out = await run_in_threadpool(
        _mark_conversation_read,
        conversation_id,
        current_user.id,
        payload.message_id if payload else None,
    )
    if read_out.changed:
        await chat_ws_manager.broadcast(
            conversation_id=conversation_id,
            payload=_message_read_payload(
                conversation_id=conversation_id,
                user_id=current_user.id,
                read_out=read_out,
            ),
        )
        await _broadcast_admin_message_read(
            conversation_id=conversation_id,
            user_id=current_user.id,
            read_out=read_out,
        )
    return read_out


@router.websocket("/ws/admin")
async def websocket_admin(websocket: WebSocket):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Missing token")
        return

    db = SessionLocal()
    admin_id: Optional[int] = None
    try:
        user = _get_ws_user_from_token(db, token)
        if not user or user.role != UserRole.ADMIN:
            await websocket.close(code=1008, reason="Forbidden")
            return

        admin_id = user.id
    finally:
        db.close()

    await chat_ws_manager.connect_admin(admin_id=admin_id, websocket=websocket)
    try:
        await chat_ws_manager.send_personal(
            websocket,
            {
                "event": "connected",
                "scope": "admin",
                "user_id": admin_id,
            },
        )
        while True:
            try:
                payload = await websocket.receive_json()
            except ValueError:
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_json",
                        "message": "Payload must be valid JSON.",
                    },
                )
                continue

            if not isinstance(payload, dict):
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_payload",
                        "message": "Payload must be a JSON object.",
                    },
                )
                continue

            if payload.get("event") == "ping":
                await chat_ws_manager.send_personal(websocket, {"event": "pong"})
                continue

            await chat_ws_manager.send_personal(
                websocket,
                {
                    "event": "error",
                    "code": "unsupported_event",
                    "message": "Unsupported event.",
                },
            )
    except WebSocketDisconnect:
        chat_ws_manager.disconnect_admin(admin_id, websocket)
    except Exception:
        chat_ws_manager.disconnect_admin(admin_id, websocket)
        try:
            await websocket.close(code=1011)
        except Exception:
            pass


@router.websocket("/ws/conversations/{conversation_id}")
async def websocket_conversation(websocket: WebSocket, conversation_id: int):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=1008, reason="Missing token")
        return

    db = SessionLocal()
    user_id: Optional[int] = None
    try:
        user = _get_ws_user_from_token(db, token)
        if not user:
            await websocket.close(code=1008, reason="Invalid token")
            return

        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if not conversation or user.id not in (conversation.user_id, conversation.admin_id):
            await websocket.close(code=1008, reason="Forbidden")
            return

        user_id = user.id
    finally:
        db.close()

    await chat_ws_manager.connect(conversation_id=conversation_id, user_id=user_id, websocket=websocket)
    try:
        await chat_ws_manager.send_personal(
            websocket,
            {
                "event": "connected",
                "conversation_id": conversation_id,
                "user_id": user_id,
            },
        )
        while True:
            try:
                payload = await websocket.receive_json()
            except ValueError:
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_json",
                        "message": "Payload must be valid JSON.",
                    },
                )
                continue

            if not isinstance(payload, dict):
                await chat_ws_manager.send_personal(
                    websocket,
                    {
                        "event": "error",
                        "code": "invalid_payload",
                        "message": "Payload must be a JSON object.",
                    },
                )
                continue

            event = payload.get("event")

            if event == "ping":
                await chat_ws_manager.send_personal(websocket, {"event": "pong"})
                continue

            if event in ("typing:start", "typing:stop"):
                await chat_ws_manager.broadcast(
                    conversation_id=conversation_id,
                    payload={
                        "event": event,
                        "conversation_id": conversation_id,
                        "user_id": user_id,
                    },
                    exclude_user_id=user_id,
                )
                continue

            if event == "message:send":
                data = payload.get("data") or {}
                if not isinstance(data, dict):
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "invalid_payload",
                            "message": "data must be a JSON object.",
                        },
                    )
                    continue

                try:
                    message_out = await run_in_threadpool(
                        _create_message,
                        conversation_id,
                        user_id,
                        None,
                        data.get("content"),
                        data.get("client_msg_id"),
                    )
                except HTTPException as exc:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "message_send_failed",
                            "status_code": exc.status_code,
                            "message": exc.detail,
                        },
                    )
                    continue
                except Exception:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "internal_error",
                            "message": "Unable to process message.",
                        },
                    )
                    continue

                await chat_ws_manager.broadcast(
                    conversation_id=conversation_id,
                    payload=_message_new_payload(conversation_id=conversation_id, message_out=message_out),
                )
                await _broadcast_admin_message_new(
                    conversation_id=conversation_id,
                    message_out=message_out,
                )
                continue

            if event == "message:read":
                data = payload.get("data") or {}
                if not isinstance(data, dict):
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "invalid_payload",
                            "message": "data must be a JSON object.",
                        },
                    )
                    continue

                try:
                    read_out = await run_in_threadpool(
                        _mark_conversation_read,
                        conversation_id,
                        user_id,
                        data.get("message_id"),
                    )
                except HTTPException as exc:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "message_read_failed",
                            "status_code": exc.status_code,
                            "message": exc.detail,
                        },
                    )
                    continue
                except Exception:
                    await chat_ws_manager.send_personal(
                        websocket,
                        {
                            "event": "error",
                            "code": "internal_error",
                            "message": "Unable to update read state.",
                        },
                    )
                    continue

                read_payload = _message_read_payload(
                    conversation_id=conversation_id,
                    user_id=user_id,
                    read_out=read_out,
                )
                if read_out.changed:
                    await chat_ws_manager.broadcast(
                        conversation_id=conversation_id,
                        payload=read_payload,
                    )
                    await _broadcast_admin_message_read(
                        conversation_id=conversation_id,
                        user_id=user_id,
                        read_out=read_out,
                    )
                else:
                    await chat_ws_manager.send_personal(websocket, read_payload)
                continue

            await chat_ws_manager.send_personal(
                websocket,
                {
                    "event": "error",
                    "code": "unsupported_event",
                    "message": "Unsupported event.",
                },
            )
    except WebSocketDisconnect:
        chat_ws_manager.disconnect(conversation_id, websocket)
    except Exception:
        chat_ws_manager.disconnect(conversation_id, websocket)
        try:
            await websocket.close(code=1011)
        except Exception:
            pass
