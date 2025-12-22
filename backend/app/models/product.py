from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base
import enum

class UnitEnum(str, enum.Enum):
    CAI = "Cái"
    CHIEC = "Chiếc"
    BO = "Bộ"
    COMBO = "ComBo"

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True)
    category_id = Column(Integer, ForeignKey("categories.id"))
    name = Column(String(255), nullable=False)
    description = Column(String(255))
    unit = Column(Enum(UnitEnum), default=UnitEnum.CHIEC, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    category = relationship("Category", back_populates="products")
    images = relationship("ImageURL", back_populates="product", cascade="all, delete")
    