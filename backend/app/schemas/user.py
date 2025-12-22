from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr
    username: str

# schema dùng cho đăng ký (cần mật khẩu)
class UserCreate(UserBase):
    password: str


# schema dùng để trả về dữ liệu cho Frontend (Bảo mật, không trả về password)
class UserOut(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True # cho phép Pydantic đọc dữ liệu từ SQLAlchemy Model
