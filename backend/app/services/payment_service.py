import math
from typing import List, Optional
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.payment import PaymentMethod
from app.models.order import Order

class PaymentService:
    @staticmethod
    def _get_blocked_payment_ids(db: Session, payment_ids: List[int]) -> set[int]:
        if not payment_ids:
            return set()

        rows = (
            db.query(Order.payment_method_id)
            .filter(Order.payment_method_id.in_(payment_ids))
            .distinct()
            .all()
        )
        return {row[0] for row in rows if row[0] is not None}

    @staticmethod
    def _attach_delete_permissions(db: Session, payments: List[PaymentMethod]) -> None:
        payment_ids = [item.id for item in payments if getattr(item, "id", None) is not None]
        blocked_ids = PaymentService._get_blocked_payment_ids(db, payment_ids)

        for payment in payments:
            setattr(payment, "can_delete", payment.id not in blocked_ids)

    @staticmethod
    def ensure_payment_can_delete(db: Session, payment_id: int) -> PaymentMethod:
        payment = PaymentService.get_id(db, payment_id)
        blocked_ids = PaymentService._get_blocked_payment_ids(db, [payment_id])

        if payment_id in blocked_ids:
            raise HTTPException(status_code=400, detail="Không thể xóa phương thức thanh toán đã dùng trong đơn hàng.")

        setattr(payment, "can_delete", True)
        return payment

    @staticmethod
    def get_active_payments(db: Session):
        return db.query(PaymentMethod).all()

    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None,
    ):
        query = db.query(PaymentMethod)

        if keyword:
            query = query.filter(PaymentMethod.name.ilike(f"%{keyword}%"))

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
            query.order_by(PaymentMethod.id.desc()).offset(skip).limit(per_page).all()
        )
        PaymentService._attach_delete_permissions(db, items)
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
    def get_id(db: Session, payment_id: int):
        payment = db.query(PaymentMethod).filter(PaymentMethod.id == payment_id).first()
        if not payment:
            raise HTTPException(status_code=404, detail="Không tìm thấy phương thức thanh toán")
        PaymentService._attach_delete_permissions(db, [payment])
        return payment

    @staticmethod
    def create(db: Session, payment_in):
        payment = PaymentMethod(**payment_in.model_dump())
        db.add(payment)
        db.commit()
        db.refresh(payment)
        return payment

    @staticmethod
    def update(db: Session, payment_id: int, payment_in):
        payment = PaymentService.get_id(db, payment_id)
        update_data = payment_in.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(payment, key, value)
        db.commit()
        db.refresh(payment)
        return payment

    @staticmethod
    def delete(db: Session, payment_id: int):
        payment = PaymentService.ensure_payment_can_delete(db, payment_id)
        db.delete(payment)
        db.commit()
        return {"message": "Xóa phương thức thanh toán thành công"}

    @staticmethod
    def seed_payments(db: Session):
        """Hàm này tạo dữ liệu mẫu"""
        if db.query(PaymentMethod).count() == 0:
            methods = [
                PaymentMethod(name="Thanh toán khi nhận hàng (COD)"),
                PaymentMethod(name="Chuyển khoản VNPAY"),
            ]
            db.add_all(methods)
            db.commit()
