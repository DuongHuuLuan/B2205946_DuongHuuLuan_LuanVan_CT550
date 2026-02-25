from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session
from app.api.deps import require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.profile import ProfileOut, ProfileUpdate
from app.services.profile_service import ProfileService


router = APIRouter(prefix="/profile", tags=["Profile"])

@router.get("/me", response_model=ProfileOut)
def get_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    return ProfileService.get_me(db, current_user.id)

@router.put("/me", response_model=ProfileOut)
def update_profile(
    profile_in: ProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    return ProfileService.update_me(db, current_user.id, profile_in)


@router.post("/me/avatar", response_model=ProfileOut)
def upload_my_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return ProfileService.upload_my_avatar(db, current_user.id, file)
