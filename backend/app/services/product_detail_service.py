from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *


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
    def get_all_sizes(db: Session):
        return db.query(Size).all()

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
        db_product_detail = db.query(ProductDetail).filter(ProductDetail.id == product_detail_in).first()
        if not db_product_detail:
            raise HTTPException(status_code=404, detail="Khong tim thay bien the san pham")

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
            raise HTTPException(status_code=404, detail="Khong tim thay bien the san pham can xoa")
        db.delete(db_product_detail)
        db.commit()
        return {"message": "Da xoa bien the san pham thanh cong"}
