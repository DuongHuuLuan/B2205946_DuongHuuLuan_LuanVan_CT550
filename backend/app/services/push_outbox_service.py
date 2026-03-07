import json
from datetime import datetime, timedelta
from typing import Dict, List

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.firebase import get_firebase_app
from app.models import NotificationOutbox, UserDevice
from app.models.push_notification import NotificationOutboxStatus
from app.services.push_notification_service import PushNotificationService


class PushOutboxService:
    @staticmethod
    def _parse_payload(payload: str) -> Dict:
        try:
            raw = json.loads(payload or "{}")
            return raw if isinstance(raw, dict) else {}
        except Exception:
            return {}

    @staticmethod
    def _serialize_data(data: Dict) -> Dict[str, str]:
        output: Dict[str, str] = {}
        for key, value in (data or {}).items():
            if value is None:
                continue
            output[str(key)] = str(value)
        return output

    @staticmethod
    def _is_invalid_token_error(exc: Exception) -> bool:
        msg = str(exc).lower()
        return (
            "registration-token-not-registered" in msg
            or "not a valid fcm registration token" in msg
            or "requested entity was not found" in msg
            or "unregistered" in msg
        )

    @staticmethod
    def _retry_or_cancel(job: NotificationOutbox, error: str) -> None:
        now = datetime.utcnow()
        job.last_error = (error or "")[:500]
        job.retry_count = (job.retry_count or 0) + 1

        if job.retry_count >= (job.max_retry or settings.PUSH_OUTBOX_MAX_RETRY):
            job.status = NotificationOutboxStatus.CANCELLED
            job.next_retry_at = None
            return

        delay = settings.PUSH_OUTBOX_RETRY_BASE_SECONDS * (2 ** max(0, job.retry_count - 1))
        job.status = NotificationOutboxStatus.FAILED
        job.next_retry_at = now + timedelta(seconds=delay)

    @staticmethod
    def process_due_jobs(db: Session, limit: int = 50) -> int:
        from firebase_admin import messaging

        now = datetime.utcnow()
        batch_size = max(1, min(limit, 500))
        jobs: List[NotificationOutbox] = (
            db.query(NotificationOutbox)
            .filter(
                NotificationOutbox.status.in_(
                    [NotificationOutboxStatus.PENDING, NotificationOutboxStatus.FAILED]
                ),
                or_(
                    NotificationOutbox.next_retry_at.is_(None),
                    NotificationOutbox.next_retry_at <= now,
                ),
            )
            .order_by(NotificationOutbox.id.asc())
            .limit(batch_size)
            .all()
        )

        processed = 0
        for job in jobs:
            processed += 1
            try:
                job.status = NotificationOutboxStatus.PROCESSING
                db.commit()
                db.refresh(job)

                payload = PushOutboxService._parse_payload(job.payload)
                title = payload.get("title") or "Tin nhắn mới"
                body = payload.get("body") or "Bạn có tin nhắn mới"
                data = PushOutboxService._serialize_data(payload.get("data") or {})

                devices = (
                    db.query(UserDevice)
                    .filter(
                        UserDevice.user_id == job.user_id,
                        UserDevice.is_active.is_(True),
                    )
                    .all()
                )
                if not devices:
                    job.status = NotificationOutboxStatus.CANCELLED
                    job.sent_at = datetime.utcnow()
                    job.last_error = "No active devices"
                    job.next_retry_at = None
                    db.commit()
                    continue

                success_count = 0
                errors: List[str] = []
                for device in devices:
                    try:
                        msg = messaging.Message(
                            token=device.push_token,
                            notification=messaging.Notification(title=title, body=body),
                            data=data,
                        )
                        messaging.send(msg, app=get_firebase_app())
                        success_count += 1
                    except Exception as exc:
                        errors.append(str(exc))
                        if PushOutboxService._is_invalid_token_error(exc):
                            PushNotificationService.deactivate_device_by_token(
                                db=db,
                                push_token=device.push_token,
                                commit=False,
                            )

                if success_count > 0:
                    job.status = NotificationOutboxStatus.SENT
                    job.sent_at = datetime.utcnow()
                    job.last_error = None
                    job.next_retry_at = None
                    db.commit()
                    continue

                PushOutboxService._retry_or_cancel(
                    job=job,
                    error=errors[0] if errors else "Push send failed",
                )
                db.commit()
            except Exception as exc:
                db.rollback()
                failed_job = (
                    db.query(NotificationOutbox)
                    .filter(NotificationOutbox.id == job.id)
                    .first()
                )
                if failed_job:
                    PushOutboxService._retry_or_cancel(failed_job, str(exc))
                    db.commit()

        return processed
