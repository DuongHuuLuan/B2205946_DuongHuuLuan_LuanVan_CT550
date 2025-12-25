from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base

class ProductDetail(Base):
    __tablename__ = "product_details"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"))
    color_id = Column(Integer, ForeignKey("colors.id"))
    size_id = Column(Integer, ForeignKey("sizes.id"))
    stock_quantity = Column(Integer, default=0)
    price = Column(Integer, nullable=True)


    product = relationship("Product", back_populates="variants")
    color = relationship("Color", back_populates="product_details")
    size = relationship("Size", back_populates="product_details")

    order_items = relationship("OrderDetail", back_populates="product_variant")
    cart_items = relationship("CartDetail", back_populates="product_variant")