from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.push_notification import UserDeviceOut, UserDeviceUpsertIn
from app.services.push_notification_service import PushNotificationService


router = APIRouter(prefix="/push", tags=["Push Notification"])


@router.get("/devices", response_model=List[UserDeviceOut])
def list_my_devices(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return PushNotificationService.list_user_devices(db=db, current_user=current_user)


@router.post("/devices", response_model=UserDeviceOut)
def register_device(
    payload: UserDeviceUpsertIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return PushNotificationService.upsert_user_device(
        db=db,
        current_user=current_user,
        platform=payload.platform,
        push_token=payload.push_token,
        device_id=payload.device_id,
    )


@router.delete("/devices")
def deactivate_device(
    push_token: str = Query(..., min_length=20, max_length=512),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    deleted = PushNotificationService.deactivate_user_device(
        db=db,
        current_user=current_user,
        push_token=push_token,
    )
    return {"success": True, "deactivated": deleted}
