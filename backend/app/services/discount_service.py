import math
from fastapi import HTTPException, status
from sqlalchemy import or_
from sqlalchemy.orm import Session
from app.models.discount import Discount, DiscountStatus
from typing import Dict, Iterable, List, Optional
from datetime import datetime

class DiscountService:

    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None
    ):
        query = db.query(Discount)

        if keyword:
            like = f"%{keyword}%"
            query = query.filter(or_(Discount.name.ilike(like), Discount.description.ilike(like)))
        
        total_count = query.count()

        if total_count == 0:
            return {
                "items": [],
                "meta": {
                    "total": 0,
                    "current_page": 1,
                    "per_page": per_page or 0,
                    "last_page": 1,
                },
            }
        
        if per_page is None:
            per_page = total_count
            page = 1
        else:
            if per_page < 1:
                per_page = 1
            if page < 1:
                page = 1
        
        skip = (page - 1) * per_page
        items = (
            query.order_by(Discount.id.desc()).offset(skip).limit(per_page).all()
        )
        last_page = math.ceil(total_count / per_page)

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }
    
    @staticmethod
    def get_id(db: Session, discount_id: int):
        discount = db.query(Discount).filter(Discount.id == discount_id).first()
        if not discount:
            raise HTTPException(status_code=404, detail="Không tìm thấy khuyến mãi")
        return discount

    @staticmethod
    def create(db: Session, discount_in):
        new_discount = Discount(
            **discount_in.model_dump(),
            status=DiscountStatus.ACTIVE,
        )
        db.add(new_discount)
        db.commit()
        db.refresh(new_discount)
        return new_discount

    @staticmethod
    def update(db: Session, discount_id: int, discount_in):
        discount = DiscountService.get_id(db, discount_id)
        update_data = discount_in.model_dump(exclude_unset=True)

        status_value = update_data.pop("status", None)
        if status_value is not None:
            if isinstance(status_value, DiscountStatus):
                discount.status = status_value
            else:
                try:
                    discount.status = DiscountStatus(status_value)
                except ValueError as exc:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Trạng thái không hợp lệ",
                    ) from exc

        for key, value in update_data.items():
            setattr(discount, key, value)

        db.commit()
        db.refresh(discount)
        return discount

    @staticmethod
    def delete(db: Session, discount_id: int):
        discount = DiscountService.get_id(db, discount_id)
        db.delete(discount)
        db.commit()
        return {"message": "Xóa khuyến mãi thành công"}

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
        
