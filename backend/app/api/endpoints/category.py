from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.models.user import User
from app.api.deps import require_admin, require_user
from app.schemas.category import CategoryCreate, CategoryOut
from app.services.category_service import CategoryService
from app.services.product_service import ProductService

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get("/", response_model=List[CategoryOut])
def getAll_category(db: Session = Depends(get_db)):
    """
    API lấy danh sách tất cả danh mục
    """
    return CategoryService.getAll_categories(db)

@router.get("/{category_id}", response_model=CategoryOut)
def get_category_id(category_id: int ,db: Session = Depends(get_db)):
    """API lấy một danh mục cụ thể"""
    return CategoryService.get_categories_id(db,category_id)

@router.post("/", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(category_in: CategoryCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API tạo danh mục mới
    """
    new_category = CategoryService.create_category(db,category_in)
    return new_category


@router.put("/{category_id}", response_model=CategoryCreate)
def update_category(category_id: int, category_in: CategoryCreate, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API cập nhật danh mục
    """
    return CategoryService.update_category(db,category_id,category_in)



@router.delete("/{category_id}", status_code=status.HTTP_200_OK)
def delete_category(category_id: int, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API  xóa danh mục
    """
    return CategoryService.delete_category(db,category_id)