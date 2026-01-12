from sqlalchemy.orm import Session
from app.models.discount import Discount, DiscountStatus
from typing import Dict, Iterable, List
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

    @staticmethod
    def get_valid_discounts_by_category_ids(
        db: Session,
        category_ids: Iterable[int],
    ) -> Dict[int, Discount]:
        category_ids = list(category_ids)
        if not category_ids:
            return {}

        now = datetime.now()
        discounts = db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now,
        ).order_by(
            Discount.category_id,
            Discount.start_at.desc(),
            Discount.id.desc(),
        ).all()

        result: Dict[int, Discount] = {}
        for discount in discounts:
            if discount.category_id not in result:
                result[discount.category_id] = discount
        return result


    @staticmethod
    def get_available_discouts_for_cart(db: Session, category_ids: List[int]):
        now = datetime.now()

        return db.query(Discount).filter(
            Discount.category_id.in_(category_ids),
            Discount.status == DiscountStatus.ACTIVE,
            Discount.start_at <= now,
            Discount.end_at >= now
        ).all()
        