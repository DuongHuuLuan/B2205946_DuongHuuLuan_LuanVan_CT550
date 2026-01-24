from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional
from app.db.session import get_db
from app.api.deps import require_admin
from app.models.user import User
from app.schemas.user import UserAdminOut, UserUpdate, UserPaginationOut
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/", response_model=UserPaginationOut)
def get_all_users(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    role: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return UserService.get_all(db, page=page, per_page=per_page, keyword=q, role=role)

@router.get("/{user_id}", response_model=UserAdminOut)
def get_user_id(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return UserService.get_id(db, user_id)

@router.put("/{user_id}", response_model=UserAdminOut)
def update_user(
    user_id: int,
    user_in: UserUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return UserService.update(db, user_id, user_in)
