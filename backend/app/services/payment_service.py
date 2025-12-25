from sqlalchemy.orm import Session
from app.models.payment import PaymentMethod

class PaymentService:
    @staticmethod
    def get_active_payments(db: Session):
        # Lấy các phương thức đang hoạt động
        return db.query(PaymentMethod).all()

    @staticmethod
    def seed_payments(db: Session):
        """Hàm tạo dữ liệu mẫu nếu chưa có"""
        if db.query(PaymentMethod).count() == 0:
            methods = [PaymentMethod(name="Thanh toán khi nhận hàng (COD)"), 
                       PaymentMethod(name="Chuyển khoản VNPAY")]
            db.add_all(methods)
            db.commit()