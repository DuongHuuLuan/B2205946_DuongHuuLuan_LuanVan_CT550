from datetime import datetime
from sqlalchemy import Column, String, Integer, ForeignKey, Text, DateTime
from sqlalchemy.orm import relationship
from app.db.base import Base

class Evaluate(Base):
    __tablename__ = "evaluates"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    rate = Column(Integer, nullable=False) # 1-5 sao
    content = Column(String(255), nullable=True)
    image = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)


    order = relationship("Order", backref="evaluation")
    user = relationship("User", backref="evaluations")