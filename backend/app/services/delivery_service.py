from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models import *
from app.schemas.order import DeliveryInfoBase

class DeliveryService:

    @staticmethod
    def create_delivery(db: Session, user_id: int, delivery_in: DeliveryInfoBase):
        # nếu đặt là mặc định, bỏ mặc định các địa chỉ cũ
        if delivery_in.default:
            db.query(DeliveryInfo).filter(DeliveryInfo.user_id == user_id).first()

        new_delivery = DeliveryInfo(**delivery_in.model_dump(), user_id = user_id)
        db.add(new_delivery)
        db.commit()
        db.refresh(new_delivery)
        return new_delivery
    
    # @staticmethod
    # def update_delivery(db: Session, delivery_id: int, delivery_in: DeliveryInfoBase):
    #     delivery = db.query(DeliveryInfo).filter(DeliveryInfo.id == delivery_id).first()

    #     if not delivery:
    #         raise HTTPException(status_code=404, detail="Không tìm thấy sổ giao hàng")

    #     new_delivery 
    @staticmethod
    def get_my_deliveries(db: Session, user_id: int):
        return db.query(DeliveryInfo).filter(DeliveryInfo.user_id == user_id).all()
    
    @staticmethod
    def delete_delivery(db: Session, delivery_id: int, user_id: int):
        delivery = db.query(DeliveryInfo).filter(DeliveryInfo.id == delivery_id, DeliveryInfo.user_id == user_id).first()
        if delivery:
            db.delete(delivery)
            db.commit()
            return True
        return False