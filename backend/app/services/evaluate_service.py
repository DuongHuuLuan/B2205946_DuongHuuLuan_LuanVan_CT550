from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models import Order, Evaluate, EvaluateImage
from app.models.order import OrderStatus
from app.models.user import User, UserRole


class EvaluateService:
    @staticmethod
    def create_evaluation(
        db: Session,
        user_id: int,
        order_id: int,
        rate: int,
        content: Optional[str],
        image_urls: List[str],
    ):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")

        if order.status != OrderStatus.COMPLETED:
            raise HTTPException(status_code=400, detail="Chỉ có thể đánh giá đơn hàng đã hoàn thành")

        existing_eval = db.query(Evaluate).filter(Evaluate.order_id == order_id).first()
        if existing_eval:
            raise HTTPException(status_code=400, detail="Bạn đã đánh giá đơn hàng này rồi")

        new_eval = Evaluate(
            order_id=order_id,
            user_id=user_id,
            rate=rate,
            content=content,
            # giữ tương thích cột cũ vì chưa xóa
            image=image_urls[0] if image_urls else None,
        )
        db.add(new_eval)
        db.flush()  # lấy new_eval.id trước khi tạo images

        for idx, url in enumerate(image_urls):
            db.add(
                EvaluateImage(
                    evaluate_id=new_eval.id,
                    image_url=url,
                    sort_order=idx,
                )
            )

        db.commit()

        review = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == new_eval.id)
            .first()
        )
        return review

    @staticmethod
    def reply_evaluation(
        db: Session,
        evaluate_id: int,
        admin_id: int,
        admin_reply: str,
    ):
        reply_text = (admin_reply or "").strip()
        if not reply_text:
            raise HTTPException(status_code=400, detail="Nội dung phản hồi không được để trống")

        review = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == evaluate_id)
            .first()
        )
        if not review:
            raise HTTPException(status_code=404, detail="Đánh giá không tồn tại")

        review.admin_id = admin_id
        review.admin_reply = reply_text
        review.admin_replied_at = datetime.now()

        db.commit()
        db.refresh(review)
        return review


    @staticmethod
    def get_admin_evaluations(
        db: Session,
        page: int = 1,
        per_page: int = 8,
        has_reply: Optional[bool] = None,
        order_id: Optional[int] = None,
    ):
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        query = db.query(Evaluate)

        if order_id is not None:
            query = query.filter(Evaluate.order_id == order_id)

        if has_reply is True:
            query = query.filter(Evaluate.admin_reply.isnot(None))
        elif has_reply is False:
            query = query.filter(Evaluate.admin_reply.is_(None))

        total = query.count()

        items = (
            query.options(joinedload(Evaluate.images))
            .order_by(Evaluate.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )

        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "items": items,
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": total_pages,
            },
        }


    @staticmethod
    def get_my_evaluations(
        db: Session,
        user_id: int,
        page: int = 1,
        per_page: int = 8,
    ):
        page = max(page, 1)
        per_page = max(1, min(per_page, 100))

        query = db.query(Evaluate).filter(Evaluate.user_id == user_id)

        total = query.count()

        items = (
            query.options(joinedload(Evaluate.images))
            .order_by(Evaluate.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
            .all()
        )

        total_pages = (total + per_page - 1) // per_page if total else 0

        return {
            "items": items,
            "meta": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": total_pages,
            },
        }
    
    @staticmethod
    def get_evaluation_by_id(
        db: Session,
        evaluate_id: int,
        current_user: User,
    ):
        query = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.id == evaluate_id)
        )

        if current_user.role != UserRole.ADMIN:
            query = query.filter(Evaluate.user_id == current_user.id)
        
        evaluate = query.first()
        if not evaluate:
            raise HTTPException(status_code=404, detail="Đánh giá không tồn tại")
        
        return evaluate

    @staticmethod
    def get_evaluation_by_order(
        db: Session,
        order_id: int,
        current_user: User,
    ):
        query = (
            db.query(Evaluate)
            .options(joinedload(Evaluate.images))
            .filter(Evaluate.order_id == order_id)
        )

        if current_user.role != UserRole.ADMIN:
            query = query.filter(Evaluate.user_id == current_user.id)

        evaluate = query.first()
        if not evaluate:
            raise HTTPException(status_code=404, detail="Đánh giá không tồn tại")

        return evaluate
