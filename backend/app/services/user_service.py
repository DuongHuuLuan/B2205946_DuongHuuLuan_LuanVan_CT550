import math
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.models.user import User, UserRole


class UserService:
    @staticmethod
    def _ensure_user_account(user: User):
        if not user or user.role != UserRole.USER:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài khoản")

    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None,
        role: Optional[str] = None,
    ):
        query = (
            db.query(User)
            .options(joinedload(User.profile))
            .filter(User.role == UserRole.USER)
        )

        if keyword:
            like = f"%{keyword}%"
            query = query.filter(or_(User.email.ilike(like), User.username.ilike(like)))

        if role:
            try:
                role_enum = UserRole(role)
            except ValueError as exc:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Role không hợp lệ",
                ) from exc
            if role_enum != UserRole.USER:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Chỉ hỗ trợ quản lý tài khoản người dùng",
                )

        total_count = query.count()
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
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1

        skip = (page - 1) * per_page
        items = query.order_by(User.id.desc()).offset(skip).limit(per_page).all()
        last_page = math.ceil(total_count / per_page)

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }

    @staticmethod
    def get_id(db: Session, user_id: int):
        user = (
            db.query(User)
            .options(joinedload(User.profile))
            .filter(User.id == user_id)
            .first()
        )
        UserService._ensure_user_account(user)
        return user

    @staticmethod
    def update(db: Session, user_id: int, user_in):
        user = UserService.get_id(db, user_id)
        update_data = user_in.model_dump(exclude_unset=True)

        email = update_data.get("email")
        if email and email != user.email:
            exists = db.query(User).filter(User.email == email, User.id != user.id).first()
            if exists:
                raise HTTPException(status_code=400, detail="Email đã tồn tại")

        username = update_data.get("username")
        if username and username != user.username:
            exists = (
                db.query(User)
                .filter(User.username == username, User.id != user.id)
                .first()
            )
            if exists:
                raise HTTPException(status_code=400, detail="Username đã tồn tại")

        role_value = update_data.pop("role", None)
        if role_value is not None:
            if isinstance(role_value, UserRole):
                role_value = role_value.value
            if role_value != UserRole.USER.value:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Không được thay đổi vai trò tài khoản",
                )

        for key, value in update_data.items():
            setattr(user, key, value)

        if username and user.profile:
            user.profile.name = username

        db.commit()
        db.refresh(user)
        return user
