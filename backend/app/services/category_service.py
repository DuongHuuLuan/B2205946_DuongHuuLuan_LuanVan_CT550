import math
from typing import Optional
from sqlalchemy import func
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.category import Category
from app.models.product import Product
from app.schemas.category import CategoryCreate
class CategoryService:
    @staticmethod
    def create_category(db: Session, category_in: CategoryCreate):
        if db.query(Category).filter(Category.name == category_in.name).first():
            raise HTTPException(status_code=400, detail="Danh mục đã tồn tại")
        
        db_category = Category(name = category_in.name)
        db.add(db_category)
        db.commit()
        db.refresh(db_category)
        return db_category
    
    # @staticmethod
    # def getAll_categories(db: Session):
    #     return db.query(Category).all()
    
    @staticmethod
    def getAll_categories(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None
    ):
        query = db.query(Category)
        if keyword:
            query = query.filter(Category.name.ilike(f"%{keyword}%"))

        
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
        items_query = (
            query.outerjoin(Product, Product.category_id == Category.id)
            .with_entities(Category, func.count(Product.id).label("products_count"))
            .group_by(Category.id)
            .order_by(Category.id.desc())
            .offset(skip)
            .limit(per_page)
        )

        items = []
        for category, count in items_query:
            setattr(category, "products_count", count)
            items.append(category)

        
        last_page = math.ceil(total_count/per_page)

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
    def get_categories_id(db: Session, category_id: int):
        category = db.query(Category).filter(Category.id == category_id).first()
        return category
    

    @staticmethod
    def update_category(db: Session, category_id: int, category_in: CategoryCreate):
        db_category = db.query(Category).filter(Category.id == category_id).first()
        if not db_category:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
        
        db_category.name = category_in.name
        db.commit()
        db.refresh(db_category)
        return db_category
    
    @staticmethod
    def delete_category(db: Session, category_id: int):
        db_category = db.query(Category).filter(Category.id == category_id).first()
        if not db_category:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
        
        if db_category.products:
            raise HTTPException(status_code=400, detail="Không thể xóa danh mục này vì vẫn còn sản phẩm bên trong.")
       
        db.delete(db_category)
        db.commit()
        return{"message": "Xóa danh mục thành công"}


    @staticmethod
    def get_product_by_category(db: Session, category_id: int):
        category = db.query(Category).filter(Category.id == category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
        
        db.commit()
        db.refresh(category)
        return category.products
