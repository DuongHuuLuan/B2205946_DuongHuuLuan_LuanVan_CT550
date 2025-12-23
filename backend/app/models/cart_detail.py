from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.db.base import Base

class CartDetail(Base):
    __tablename__ = "cart_details"

    id = Column(Integer, primary_key=True, index=True)
    cart_id = Column(Integer, ForeignKey("carts.id",ondelete="CASCADE"))
    product_detail_id = Column(Integer, ForeignKey("product_details.id", ondelete="CASCADE"))
    quantity = Column(Integer, default=1)

    created_at = Column(DateTime(timezone=True), server_default= func.now())

    cart = relationship("Cart", back_populates="items")
    product_variant = relationship("ProductDetail")