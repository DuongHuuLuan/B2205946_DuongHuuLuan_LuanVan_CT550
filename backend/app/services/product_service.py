import math
from typing import Dict, List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.category import Category
from app.models.order import OrderDetail
from app.models.product import Product
from app.models.product_detail import ProductDetail
from app.models.receipt import ReceiptDetail
from app.schemas.product import ProductCreate


class ProductService:
    @staticmethod
    def _get_delete_block_reasons(db: Session, product_ids: List[int]) -> Dict[int, str]:
        if not product_ids:
            return {}

        reasons: Dict[int, str] = {}

        receipt_rows = (
            db.query(ReceiptDetail.product_id)
            .filter(ReceiptDetail.product_id.in_(product_ids))
            .distinct()
            .all()
        )
        for row in receipt_rows:
            reasons[row[0]] = "Không thể xóa: sản phẩm đã tạo phiếu nhập"

        order_rows = (
            db.query(ProductDetail.product_id)
            .join(OrderDetail, OrderDetail.product_detail_id == ProductDetail.id)
            .filter(ProductDetail.product_id.in_(product_ids))
            .distinct()
            .all()
        )
        for row in order_rows:
            reasons.setdefault(row[0], "Không thể xóa: sản phẩm đã được bán")

        return reasons

    @staticmethod
    def _attach_delete_permissions(db: Session, products: List[Product]) -> None:
        product_ids = [p.id for p in products if getattr(p, "id", None) is not None]
        block_reasons = ProductService._get_delete_block_reasons(db, product_ids)

        for product in products:
            reason = block_reasons.get(product.id)
            setattr(product, "can_delete", reason is None)
            setattr(product, "delete_block_reason", reason)

    @staticmethod
    def create_product(db: Session, product_in: ProductCreate):
        category = db.query(Category).filter(Category.id == product_in.category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục này")

        product_data = product_in.model_dump(exclude={"images"})
        db_product = Product(**product_data)

        db.add(db_product)
        db.commit()
        db.refresh(db_product)
        return db_product

    @staticmethod
    def get_product_byID(db: Session, product_id: int):
        product = (
            db.query(Product)
            .options(joinedload(Product.product_images))
            .filter(Product.id == product_id)
            .first()
        )
        if not product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")

        ProductService._attach_delete_permissions(db, [product])
        return product

    @staticmethod
    def get_product_category(db: Session, category_id: int):
        products = (
            db.query(Product)
            .filter(Product.category_id == category_id)
            .options(joinedload(Product.category), joinedload(Product.product_images))
            .all()
        )
        if not products:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục sản phẩm")
        return products

    @staticmethod
    def update_product(db: Session, product_id: int, product_in: ProductCreate):
        db_product = db.query(Product).filter(Product.id == product_id).first()
        if not db_product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")

        update_data = product_in.model_dump(exclude_unset=True, exclude={"images"})
        for key, value in update_data.items():
            setattr(db_product, key, value)

        db.commit()
        db.refresh(db_product)
        return db_product

    @staticmethod
    def ensure_product_can_delete(db: Session, product_id: int):
        db_product = db.query(Product).filter(Product.id == product_id).first()
        if not db_product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")

        reason = ProductService._get_delete_block_reasons(db, [product_id]).get(product_id)
        if reason:
            raise HTTPException(status_code=400, detail=reason)

        return db_product

    @staticmethod
    def delete_product(db: Session, product_id: int, skip_validate: bool = False):
        if skip_validate:
            db_product = db.query(Product).filter(Product.id == product_id).first()
            if not db_product:
                raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        else:
            db_product = ProductService.ensure_product_can_delete(db, product_id)

        db.delete(db_product)
        db.commit()
        return {"message": "Đã xóa sản phẩm thành công"}

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
            joinedload(Product.product_details),
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
        ProductService._attach_delete_permissions(db, items)

        last_page = math.ceil(total_count / per_page)

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }
