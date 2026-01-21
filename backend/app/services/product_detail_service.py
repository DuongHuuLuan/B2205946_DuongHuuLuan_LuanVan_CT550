from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *
from app.schemas.product_detail import SizeUpdate


class ProductDetailService:

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
    def update_size(db: Session, size_id: int, size_in: SizeUpdate):
        db_size = db.query(Size).filter(Size.id == size_id).first()
        if not db_size:
            raise HTTPException(status_code=404, detail="Không tìm thấy size")
        
        update_data = size_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_size, key, value)

        db.commit()
        db.refresh(db_size)
        return db_size

    @staticmethod
    def get_all_sizes(db: Session):
        return db.query(Size).all()

    
    @staticmethod
    def delete_size(db: Session, size_id: int):
        db_size = db.query(Size).filter(Size.id == size_id).first()

        if not db_size:
            raise HTTPException(status_code=404, detail="Không tìm thấy size")
        
        used = db.query(ProductDetail).filter(ProductDetail.size_id == size_id).first()
        if used:
            raise HTTPException(status_code=400, detail="Size đang được sử dụng")
        
        db.delete(db_size)
        db.commit()
        return {"message": "Đã xóa size thành công"}

    @staticmethod
    def create_product_detail(db: Session, product_detail_in: ProductDetailCreate, product_id: int):
        existing_product_detail = db.query(ProductDetail).filter(
            ProductDetail.product_id == product_id,
            ProductDetail.color_id == product_detail_in.color_id,
            ProductDetail.size_id == product_detail_in.size_id,
        ).first()
        if existing_product_detail:
            existing_product_detail.price = product_detail_in.price
            db.commit()
            db.refresh(existing_product_detail)
            return existing_product_detail

        db_product_detail = ProductDetail(
            product_id=product_id,
            **product_detail_in.model_dump()
        )

        db.add(db_product_detail)
        db.commit()
        db.refresh(db_product_detail)
        return db_product_detail

    @staticmethod
    def update_product_detail(db: Session, product_detail_id: int, product_detail_in: ProductDetailUpdate):
        db_product_detail = db.query(ProductDetail).filter(ProductDetail.id == product_detail_id).first()
        if not db_product_detail:
            raise HTTPException(status_code=404, detail="Không tìm thấy biến thể sản phẩm")

        update_data = product_detail_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_product_detail, key, value)

        db.commit()
        db.refresh(db_product_detail)
        return db_product_detail

    @staticmethod
    def delete_product_detail(db: Session, product_detail_id: int):
        db_product_detail = db.query(ProductDetail).filter(ProductDetail.id == product_detail_id).first()
        if not db_product_detail:
            raise HTTPException(status_code=404, detail="Không tìm thấy biến thế sản phẩm cần xóa")
        db.delete(db_product_detail)
        db.commit()
        return {"message": "Đã xóa biến thế sản phẩm thành công"}
