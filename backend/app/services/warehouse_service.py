from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.models.warehouse import Warehouse, WarehouseDetail
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
    def delete_warehouse(
        db: Session,
        warehouse_id: int
    ):
        warehouse = WarehouseService.get_id(db, warehouse_id)
        has_stock = db.query(WarehouseDetail).filter(WarehouseDetail.warehouse_id == warehouse_id).first()
        if has_stock:
            raise HTTPException(status_code=400, detail="Không thể xóa kho đang chứa hàng")

        db.delete(warehouse)
        db.commit()
        return {"message":"Đã xóa kho hàng thành công"}