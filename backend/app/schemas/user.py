from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr
    username: str

# schema dùng cho đăng ký (cần mật khẩu)
class UserCreate(UserBase):
    password: str

#schema dùng để đổi mật khẩu
class PasswordChange(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6)

# schema dùng để trả về dữ liệu cho Frontend (Bảo mật, không trả về password)
class UserOut(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True # cho phép Pydantic đọc dữ liệu từ SQLAlchemy Model
