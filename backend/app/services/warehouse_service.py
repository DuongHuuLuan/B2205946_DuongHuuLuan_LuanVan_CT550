from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException
from app.models.warehouse import Warehouse, WarehouseDetail
from app.models.product_detail import ProductDetail
from app.schemas.warehouse import WarehouseCreate, WarehouseDetailOut, WarehouseOut


class WarehouseService:
    @staticmethod
    def create_warehouse(db: Session, warehouse_in: WarehouseCreate):
        db_warehouse = Warehouse(**warehouse_in.model_dump())
        db.add(db_warehouse)
        db.commit()
        db.refresh(db_warehouse)
        return db_warehouse

    @staticmethod
    def get_all(db: Session):
        return db.query(Warehouse).all()

    @staticmethod
    def get_id(db: Session, warehouse_id: int):
        warehouse = db.query(Warehouse).filter(Warehouse.id == warehouse_id).first()
        if not warehouse:
            raise HTTPException(status_code=404, detail="Kho khong ton tai")
        return warehouse
    
    @staticmethod
    def get_warehouse_detail(db: Session, warehouse_id: int):
        warehouse = db.query(WarehouseDetail).filter(WarehouseDetail.warehouse_id == warehouse_id).all()

        if not warehouse:
            raise HTTPException(status_code=404, detail="Kho không tồn tại")
        return warehouse

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
        has_stock = db.query(WarehouseDetail).filter(WarehouseDetail.warehouse_id == warehouse_id).first()
        if has_stock:
            raise HTTPException(status_code=400, detail="Khong the xoa kho dang con hang")

        db.delete(warehouse)
        db.commit()
        return {"message": "Da xoa kho thanh cong"}

    @staticmethod
    def get_quantity_product_detail_id(db: Session, product_id: int, size_id: int, color_id: int) -> int:
        result = db.query(
            func.coalesce(func.sum(WarehouseDetail.quantity), 0)
        ).filter(
            WarehouseDetail.product_id == product_id,
            WarehouseDetail.size_id == size_id,
            WarehouseDetail.color_id == color_id
        ).scalar()
        
        return int(result)  
    
    @staticmethod
    def get_total_stock(db: Session, product_detail: ProductDetail) -> int:
        if not product_detail:
            return 0
        return WarehouseService.get_quantity_product_detail_id(
            db, 
            product_id=product_detail.product_id, 
            size_id=product_detail.size_id, 
            color_id=product_detail.color_id
        )

    @staticmethod
    def decrease_stock(db: Session, product_detail: ProductDetail, quantity: int):
        if quantity <= 0:
            return
        stocks = db.query(WarehouseDetail).filter(
            WarehouseDetail.product_id == product_detail.product_id,
            WarehouseDetail.color_id == product_detail.color_id,
            WarehouseDetail.size_id == product_detail.size_id
        ).order_by(WarehouseDetail.warehouse_id.asc()).all()

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
        stock = db.query(WarehouseDetail).filter(
            WarehouseDetail.product_id == product_detail.product_id,
            WarehouseDetail.color_id == product_detail.color_id,
            WarehouseDetail.size_id == product_detail.size_id
        ).order_by(WarehouseDetail.warehouse_id.asc()).first()

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
            quantity=quantity
        )
        db.add(new_stock)


   