from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Numeric, Enum, func
from sqlalchemy.orm import relationship
from app.db.base import Base
import enum
from datetime import datetime

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    SHIPPING = "shipping"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    delivery_info_id = Column(Integer, ForeignKey("delivery_info.id"))
    payment_method_id = Column(Integer, ForeignKey("payment_methods.id"))
    rank_discount = Column(Numeric(10,2), default=0.0)
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="orders")
    order_details = relationship("OrderDetail", back_populates="order", cascade="all, delete-orphan")
    delivery_info = relationship("DeliveryInfo", back_populates="orders")
    payment_method = relationship("PaymentMethod", back_populates="orders")
    applied_discounts = relationship(
        "Discount", 
        secondary="order_discounts", 
        back_populates="orders"
    )


class OrderDetail(Base):
    __tablename__ = "order_details"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"))
    product_detail_id = Column(Integer, ForeignKey("product_details.id"))
    quantity = Column(Integer, nullable=False)
    price = Column(Numeric(10,2), nullable=False)

    order = relationship("Order", back_populates="order_details")
    product_detail= relationship("ProductDetail")
