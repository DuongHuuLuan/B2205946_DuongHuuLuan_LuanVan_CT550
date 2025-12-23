from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *

class VariantService:

    @staticmethod
    def create_color(db: Session, color_in: ColorCreate):
        db_color = Color(**color_in.model_dump())
        db.add(db_color)
        db.commit()
        db.refresh(db_color)
        return db_color
    
    @staticmethod
    def get_all_colors(db: Session):
        return db.query(Color).all()
    
    @staticmethod
    def create_size(db: Session, size_in: SizeCreate):
        db_size = Size(**size_in.model_dump())
        db.add(db_size)
        db.commit()
        db.refresh(db_size)
        return db_size
    
    @staticmethod
    def get_all_sizes(db: Session):
        return db.query(Size).all()
    



    @staticmethod
    def create_variant(db: Session, variant_in: VariantCreate, product_id: int):
        existing_variant = db.query(ProductDetail).filter(
            ProductDetail.product_id == product_id,
            ProductDetail.color_id == variant_in.color_id,
            ProductDetail.size_id == variant_in.size_id,
        ).first()
        if existing_variant:
            #nếu tồn tại rồi thì cộng dồn số lương kho
            existing_variant.stock_quantity += variant_in.stock_quantity
            db.commit()
            db.refresh(existing_variant)
            return existing_variant

            #nếu chưa có thì mới tạo mới
        db_variant = ProductDetail(
            product_id = product_id,
            **variant_in.model_dump()
        )

        db.add(db_variant)
        db.commit()
        db.refresh(db_variant)
        return db_variant
    

    @staticmethod
    def update_variant(db: Session, variant_id: int, quantity: int):
        db_variant = db.query(ProductDetail).filter(ProductDetail.id == variant_id).first()
        if not db_variant:
            raise HTTPException(status_code=404, detail="Không tìm thấy biến thể sản phẩm")
        db_variant.stock_quantity = quantity
        db.commit()
        db.refresh(db_variant)
        return db_variant
    
    @staticmethod
    def delete_variant(db: Session, variant_id: int):
        db_variant = db.query(ProductDetail).filter(ProductDetail.id == variant_id).first()
        if not db_variant:
            raise HTTPException(status_code=404, detail="Không tìm thấy biến thể sản phẩm cần xóa")
        db.delete(db_variant)
        db.commit()
        return {"message":"Đã xóa biến thế sản phẩm thành công"}
    