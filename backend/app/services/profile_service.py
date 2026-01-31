from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.profile import Profile
from app.models.user import User
from app.schemas.profile import ProfileUpdate

class ProfileService:

    @staticmethod
    def get_me(db: Session, user_id: int):
        profile = db.query(Profile).filter(Profile.user_id == user_id).first()
        if profile:
            return profile

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Không tìm thấy người dùng")
        
        profile = Profile(user_id = user_id, name = user.username)
        db.add(profile)
        db.commit()
        db.refresh(profile)
        return profile
    

    @staticmethod
    def update_me(db: Session, user_id: int, profile_in: ProfileUpdate) -> Profile:
        profile = db.query(Profile).filter(Profile.user_id == user_id).first()

        if not profile:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Không tìm thấy người dùng",
                )
            profile = Profile(user_id=user.id, name=user.username)
            db.add(profile)
            db.flush()

        update_data = profile_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(profile, key, value)

        db.commit()
        db.refresh(profile)
        return profile

