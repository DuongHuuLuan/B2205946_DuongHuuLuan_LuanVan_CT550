from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.user import UserCreate, UserOut
from app.services.auth_service import auth_service
from app.api import deps
from app.models.user import User
from pydantic import BaseModel, EmailStr
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter()

#schema dùng cho request đăng nhập
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    Tạo tài khoản mới. Mặc định role là 'user'
    """
    return auth_service.register_user(db, user_in)

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Xác thực và cấp "chìa khóa" JWT TOken chứa Id và Role. 
    """
    try:
        token = auth_service.login_user(db, email= form_data.username, password=form_data.password)
        return {
            "access_token": token,
            "token_type": "bearer"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    

@router.get("/me", response_model=UserOut)
def read_user_me(current_user: User = Depends(deps.get_current_user)):
    """
    Lấy thông tin người dùng đang đăng nhập dựa vào Token gửi kèm.
    """
    return current_user

# API thử nghiệm quyền Admin
@router.get("/admin")
def test_admin_access(admin_user: User = Depends(deps.require_admin)):
    """
    API Test để xem chức năng phân quyền Admin có hoạt động khoogn. 
    """
    return {"message":f"Chào Amin{admin_user.username}, bạn có quyền truy cập! "}