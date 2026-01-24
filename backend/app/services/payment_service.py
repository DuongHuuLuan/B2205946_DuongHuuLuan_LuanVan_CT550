import math
from typing import Optional
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.payment import PaymentMethod

class PaymentService:
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
            raise HTTPException(status_code=404, detail="Khong tim thay phuong thuc thanh toan")
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
        payment = PaymentService.get_id(db, payment_id)
        db.delete(payment)
        db.commit()
        return {"message": "Xoa phuong thuc thanh toan thanh cong"}

    @staticmethod
    def seed_payments(db: Session):
        """Ham tao du lieu mau neu chua co"""
        if db.query(PaymentMethod).count() == 0:
            methods = [
                PaymentMethod(name="Thanh toan khi nhan hang (COD)"),
                PaymentMethod(name="Chuyen khoan VNPAY"),
            ]
            db.add_all(methods)
            db.commit()
