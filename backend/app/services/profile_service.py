import cloudinary.uploader
from fastapi import HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.models.profile import Profile
from app.models.user import User
from app.schemas.profile import ProfileUpdate


class ProfileService:
    @staticmethod
    def _get_or_create_profile(db: Session, user_id: int) -> Profile:
        profile = db.query(Profile).filter(Profile.user_id == user_id).first()
        if profile:
            return profile

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Khong tim thay nguoi dung",
            )

        profile = Profile(user_id=user.id, name=user.username)
        db.add(profile)
        db.flush()
        return profile

    @staticmethod
    def get_me(db: Session, user_id: int) -> Profile:
        profile = db.query(Profile).filter(Profile.user_id == user_id).first()
        if profile:
            return profile

        profile = ProfileService._get_or_create_profile(db, user_id)
        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def update_me(db: Session, user_id: int, profile_in: ProfileUpdate) -> Profile:
        profile = ProfileService._get_or_create_profile(db, user_id)

        update_data = profile_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(profile, key, value)

        db.commit()
        db.refresh(profile)
        return profile

    @staticmethod
    def upload_my_avatar(db: Session, user_id: int, file: UploadFile) -> Profile:
        if not (file.content_type or "").startswith("image/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File phai la anh",
            )

        profile = ProfileService._get_or_create_profile(db, user_id)
        old_public_id = profile.avatar_public_id
        new_public_id = None

        try:
            upload_result = cloudinary.uploader.upload(
                file.file,
                folder="helmet_shop/avatars",
            )
            profile.avatar = upload_result.get("secure_url")
            new_public_id = upload_result.get("public_id")
            profile.avatar_public_id = new_public_id

            db.commit()
            db.refresh(profile)
        except Exception:
            db.rollback()
            if new_public_id:
                try:
                    cloudinary.uploader.destroy(new_public_id)
                except Exception:
                    pass
            raise

        if old_public_id and old_public_id != new_public_id:
            try:
                cloudinary.uploader.destroy(old_public_id)
            except Exception:
                pass

        return profile
