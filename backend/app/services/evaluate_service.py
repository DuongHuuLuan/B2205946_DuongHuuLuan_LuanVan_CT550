from sqlalchemy.orm import Session
from app.models import *
from app.models.order import OrderStatus
from app.schemas.evaluate import EvaluateCreate
from fastapi import HTTPException

class EvaluateService:
    @staticmethod
    def create_evaluation(db: Session, user_id: int, order_id: int, rate: int, content: str, image_url: str):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
        
        #chi mua hang moi duoc review (trang thai phai la completed)
        if order.status != OrderStatus.COMPLETED:
            raise HTTPException(status_code=400, detail="Chỉ có thể đánh giá đơn hàng đã hoàn thành")
        
        #kiểm tra xem đã đánh giá chưa
        existing_eval = db.query(Evaluate).filter(Evaluate.order_id == order_id).first()
        if existing_eval:
            raise HTTPException(status_code=400, detail="Bạn đã đánh giá đơn hàng này rồi")
        
        new_eval = Evaluate(
            order_id = order_id,
            user_id = user_id,
            rate = rate,
            content = content,
            image = image_url
        )
        db.add(new_eval)
        db.commit()
        db.refresh(new_eval)
        return new_eval