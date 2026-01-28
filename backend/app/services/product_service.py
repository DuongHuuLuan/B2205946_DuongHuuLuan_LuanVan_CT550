import math
from typing import Optional
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from app import models
from app.models.product import Product
from app.models.category import Category
from app.schemas.product import ProductCreate

class ProductService:
    @staticmethod
    def create_product(db: Session, product_in: ProductCreate):
        category = db.query(Category).filter(Category.id == product_in.category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục này")
        
        product_data = product_in.model_dump(exclude={'images'})
        db_product = Product(**product_data)
        
        db.add(db_product)
        db.commit()
        db.refresh(db_product)
        return db_product


    @staticmethod
    def get_product_byID(db: Session, product_id: int):
        product = db.query(Product).options(joinedload(Product.product_images)).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        return product 
    
## hàm lấy tất cả sản phẩm theo danh mục
    @staticmethod
    def get_product_category(db: Session, category_id: int):
        products = db.query(Product).filter(Product.category_id == category_id).options(joinedload(Product.category), joinedload(Product.product_images)).all()
        if not products:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục sản phẩm")
        return products

    @staticmethod
    def update_product(db: Session, product_id: int, product_in: ProductCreate):
        db_product = db.query(Product).filter(Product.id == product_id).first()
        if not db_product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")

        update_data = product_in.model_dump(exclude_unset=True, exclude={'images'})   ## chỉ lấy những trường có gửi dữ liệu
        for key, value in update_data.items():
            setattr(db_product, key, value)


        db.commit()
        db.refresh(db_product)
        return db_product
    
    @staticmethod
    def delete_product(db: Session, product_id: int):
        db_product = db.query(Product).filter(Product.id == product_id).first()
        if not db_product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        
        db.delete(db_product)
        db.commit()
        return  {"message": "Đã chuyển sản phẩm vào thùng rác"}
    
    @staticmethod
    def get_products_paginated(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None,
        category_id: Optional[int] = None,
    ):
        query = db.query(Product).options(
            joinedload(Product.category),
            joinedload(Product.product_images),
            joinedload(Product.product_details)
        )

        if category_id is not None:
            query = query.filter(Product.category_id == category_id)

        if keyword:
            query = query.filter(Product.name.ilike(f"%{keyword}%"))

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
        items = query.order_by(Product.id.asc()).offset(skip).limit(per_page).all()

        last_page = math.ceil(total_count / per_page)

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page
            }
        }
