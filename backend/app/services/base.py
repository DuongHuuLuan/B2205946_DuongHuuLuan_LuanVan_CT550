from typing import Type, TypeVar, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

ModelType = TypeVar("ModelType")

class BaseService:
    @staticmethod
    def get_or_404(db: Session, model: Type[ModelType], id: Any, detail: str = "Không tìm thấy dữ liệu") -> ModelType:
        obj = db.query(model).filter(model.id == id).first()
        if not obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail=detail
            )
        return obj

    @staticmethod
    def assert_owner(user_id: int, owner_id: int, detail: str = "Bạn không có quyền thực hiện hành động này"):
        if user_id != owner_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail=detail
            )