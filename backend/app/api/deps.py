from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from app.core.config import settings
from app.db.session import get_db
from app.models.user import User, UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login/admin")


def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
) -> User:
    """
    Dependency dùng để lấy User hiện tại từ JWT Tokken.
    Bất kỳ API nào dùng hàm này điều yêu cầu phải có Token hợp lệ. 
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Không thể xác thực thông tin đăng nhập",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # giải mã token bằng SECRET_KEY
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")

        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # tìm User trong Database từ ID giải được
    user = db.query(User).filter(User.id == user_id).first()

    if user is None:
        raise credentials_exception
    
    return user

# def get_current_admin(current_user: User = Depends(get_current_user)) -> User:
#     """
#     Dependency mở rộng để kiểm tra quyền Admin. 
#     Dựa trên role đã định nghĩa trong model User
#     """

#     if current_user.role.value != "admin":
#         raise HTTPException(
#             status_code=status.HTTP_403_FORBIDDEN,
#             detail="Bạn không có quyền thực hiện hành động này"
#         )
#     return current_user
def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """
    Tầng 2: Phân quyền Admin (Authorization)
    Chỉ cho phép Admin đi qua.
    """
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Yêu cầu quyền ADMIN để thực hiện hành động này"
        )
    return current_user

def require_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Tầng 2: Phân quyền User (Authorization)
    Cho phép cả User thường và Admin (vì Admin cũng là một User).
    """
    if current_user.role not in [UserRole.USER, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập"
        )
    return current_user