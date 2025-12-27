from sqlalchemy.orm import Session
from app.models.discount import Discount, DiscountStatus
from datetime import datetime

class DiscountService:
    @staticmethod
    def get_valid_discount(db: Session, code_name: str):
        now = datetime.now()
        return db.query(Discount).filter(
            Discount.name == code_name,
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <=  now,
            Discount.end_at >= now
        ).first()