import math
from typing import Optional
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from fastapi import HTTPException
from app.models.warehouse import Warehouse, WarehouseDetail
from app.models.product import Product
from app.models.product_detail import ProductDetail
from app.schemas.warehouse import WarehouseCreate


class WarehouseService:
    @staticmethod
    def create_warehouse(db: Session, warehouse_in: WarehouseCreate):
        db_warehouse = Warehouse(**warehouse_in.model_dump())
        db.add(db_warehouse)
        db.commit()
        db.refresh(db_warehouse)
        return db_warehouse

    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None,
    ):
        query = db.query(Warehouse)
        if keyword:
            query = query.filter(Warehouse.address.ilike(f"%{keyword}%"))

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
            query.outerjoin(WarehouseDetail, WarehouseDetail.warehouse_id == Warehouse.id)
            .with_entities(
                Warehouse,
                func.count(func.distinct(WarehouseDetail.product_id)).label("products_count"),
                func.coalesce(func.sum(WarehouseDetail.quantity), 0).label("total_quantity"),
            )
            .group_by(Warehouse.id)
            .order_by(Warehouse.id.desc())
            .offset(skip)
            .limit(per_page)
        )

        items = []
        for warehouse, products_count, total_quantity in items_query:
            setattr(warehouse, "products_count", int(products_count or 0))
            setattr(warehouse, "total_quantity", int(total_quantity or 0))
            setattr(warehouse, "pending_quantity", 0)
            items.append(warehouse)

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

    @staticmethod
    def get_id(db: Session, warehouse_id: int):
        warehouse = db.query(Warehouse).filter(Warehouse.id == warehouse_id).first()
        if not warehouse:
            raise HTTPException(status_code=404, detail="Kho khong ton tai")

        summary = db.query(
            func.count(func.distinct(WarehouseDetail.product_id)).label("products_count"),
            func.coalesce(func.sum(WarehouseDetail.quantity), 0).label("total_quantity"),
        ).filter(WarehouseDetail.warehouse_id == warehouse_id).first()

        setattr(warehouse, "products_count", int(summary.products_count or 0))
        setattr(warehouse, "total_quantity", int(summary.total_quantity or 0))
        setattr(warehouse, "pending_quantity", 0)
        return warehouse

    @staticmethod
    def get_warehouse_detail(
        db: Session,
        warehouse_id: int,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None,
        category_id: Optional[int] = None,
    ):
        warehouse = WarehouseService.get_id(db, warehouse_id)

        detail_query = db.query(WarehouseDetail).filter(
            WarehouseDetail.warehouse_id == warehouse_id
        )
        if keyword or category_id is not None:
            detail_query = detail_query.join(
                Product, WarehouseDetail.product_id == Product.id
            )
        if keyword:
            detail_query = detail_query.filter(Product.name.ilike(f"%{keyword}%"))
        if category_id is not None:
            detail_query = detail_query.filter(Product.category_id == category_id)

        total_count = detail_query.count()
        if total_count == 0:
            return {
                "warehouse": warehouse,
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
        items = (
            detail_query.options(
                joinedload(WarehouseDetail.product).joinedload(Product.category),
                joinedload(WarehouseDetail.product).joinedload(Product.product_images),
                joinedload(WarehouseDetail.product).joinedload(Product.product_details),
                joinedload(WarehouseDetail.color),
                joinedload(WarehouseDetail.size),
            )
            .order_by(WarehouseDetail.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        last_page = math.ceil(total_count / per_page)
        return {
            "warehouse": warehouse,
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }

    @staticmethod
    def update_warehouse(db: Session, warehouse_id: int, warehouse_in: WarehouseCreate):
        warehouse = WarehouseService.get_id(db, warehouse_id)

        warehouse_data = warehouse_in.model_dump(exclude_unset=True)

        for key, value in warehouse_data.items():
            setattr(warehouse, key, value)

        db.commit()
        db.refresh(warehouse)
        return warehouse

    @staticmethod
    def delete_warehouse(db: Session, warehouse_id: int):
        warehouse = WarehouseService.get_id(db, warehouse_id)
        has_stock = (
            db.query(WarehouseDetail)
            .filter(WarehouseDetail.warehouse_id == warehouse_id)
            .first()
        )
        if has_stock:
            raise HTTPException(status_code=400, detail="Khong the xoa kho dang con hang")

        db.delete(warehouse)
        db.commit()
        return {"message": "Da xoa kho thanh cong"}

    @staticmethod
    def get_quantity_product_detail_id(
        db: Session, product_id: int, size_id: int, color_id: int
    ) -> int:
        result = (
            db.query(func.coalesce(func.sum(WarehouseDetail.quantity), 0))
            .filter(
                WarehouseDetail.product_id == product_id,
                WarehouseDetail.size_id == size_id,
                WarehouseDetail.color_id == color_id,
            )
            .scalar()
        )

        return int(result)

    @staticmethod
    def get_total_stock(db: Session, product_detail: ProductDetail) -> int:
        if not product_detail:
            return 0
        return WarehouseService.get_quantity_product_detail_id(
            db,
            product_id=product_detail.product_id,
            size_id=product_detail.size_id,
            color_id=product_detail.color_id,
        )

    @staticmethod
    def decrease_stock(db: Session, product_detail: ProductDetail, quantity: int):
        if quantity <= 0:
            return
        stocks = (
            db.query(WarehouseDetail)
            .filter(
                WarehouseDetail.product_id == product_detail.product_id,
                WarehouseDetail.color_id == product_detail.color_id,
                WarehouseDetail.size_id == product_detail.size_id,
            )
            .order_by(WarehouseDetail.warehouse_id.asc())
            .all()
        )

        remaining = quantity
        for stock in stocks:
            if remaining <= 0:
                break
            if stock.quantity >= remaining:
                stock.quantity -= remaining
                remaining = 0
            else:
                remaining -= stock.quantity
                stock.quantity = 0

        if remaining > 0:
            raise HTTPException(status_code=400, detail="Khong du hang trong kho")

    @staticmethod
    def increase_stock(db: Session, product_detail: ProductDetail, quantity: int):
        if quantity <= 0:
            return
        stock = (
            db.query(WarehouseDetail)
            .filter(
                WarehouseDetail.product_id == product_detail.product_id,
                WarehouseDetail.color_id == product_detail.color_id,
                WarehouseDetail.size_id == product_detail.size_id,
            )
            .order_by(WarehouseDetail.warehouse_id.asc())
            .first()
        )

        if stock:
            stock.quantity += quantity
            return

        warehouse = db.query(Warehouse).order_by(Warehouse.id.asc()).first()
        if not warehouse:
            raise HTTPException(status_code=400, detail="Khong co kho de hoan hang")

        new_stock = WarehouseDetail(
            warehouse_id=warehouse.id,
            product_id=product_detail.product_id,
            color_id=product_detail.color_id,
            size_id=product_detail.size_id,
            quantity=quantity,
        )
        db.add(new_stock)
