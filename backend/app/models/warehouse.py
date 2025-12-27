from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Numeric, Enum, func
from sqlalchemy.orm import relationship
from app.db.base import Base
import enum


class Warehouse(Base):
    __tablename__ = "warehouses"
    id = Column(Integer, primary_key=True, index=True)
    address = Column(String(255),nullable=False)
    capacity = Column(Integer)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())


class WarehouseDetail(Base):
    __tablename__ = "warehouse_details"
    id = Column(Integer, primary_key=True, index=True)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"))
    product_detail_id = Column(Integer, ForeignKey("product_details.id"))
    quantity = Column(Integer, default=0) # so luong ton kho thuc te tai kho