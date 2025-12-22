from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import User
from app.models.profile import Profile
from app.core.security import get_password_hash, verify_password, created_access_token
from app.schemas.user import UserCreate

class AuthService:
    @staticmethod
    def register_user(db: Session, user_in: UserCreate):
        if db.query(User).filter(User.email == user_in.email).first():
            raise HTTPException(status_code=400, detail="Email đã tồn tại")
        
        # tạo user với mật khẩu đã băm
        db_user = User(
            email = user_in.email,
            username = user_in.username,
            password = get_password_hash(user_in.password),
            role ="user"
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        # tạo profile đi kèm
        db_profile = Profile(
            user_id = db_user.id,
            name = db_user.username,
            gender = "male"
        )
        db.add(db_profile)
        db.commit()
        return db_user
    
    @staticmethod
    def login_user(db: Session, email: str, password: str):
        user = db.query(User).filter(User.email == email).first()
        if not user or not verify_password(password, user.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Sai email hoặc mật khẩu"
            )
        
        # tạo token chứa sub(ID) và role
        token = created_access_token(
            subject=user.id,
            role=user.role.value # lấy chuỗi "admin" hoặc "user" từ Enum
        )
        return token

auth_service = AuthService()
