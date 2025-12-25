from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from app.models import *
from app.models.order import OrderStatus
from app.schemas import *
from typing import List

class OrderService:

    @staticmethod
    def create_order(db: Session, user_id: int, order_in: OrderCreate):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart or not cart.items:
            raise HTTPException(status_code=400, detail= "Giỏ hàng trống")
        
        total_price = 0
        order_items_to_create = []

        for cart_item in cart.items:
            variant = db.query(ProductDetail).filter(ProductDetail.id == cart_item.product_detail_id)

            if not variant or variant.stock_quantity < cart_item.quantity:
                raise HTTPException(
                    status_code=400,
                    detail= f"Sản phẩm {variant.product.name if variant else 'ID'+ str(cart_item.product_detail_id)} không đủ hàng"
                )

            #tinh tien (gia tai thoi diem mua)
            total_price += variant.price *cart_item.quantity

            #chuan bi du lieu cho OrderDetail
            order_items_to_create.append({
                "product_detail_id": variant.id,
                "quantity": cart_item.quantity,
                "price": variant.price
            })

            # tru kho
            variant.stock_quantity -= cart_item.quantity

        #tinh rank_discount
        # chổ này ví dụ đang tính là 5%
        discount = total_price * 0.05 

        # tạo order header
        new_order = Order(
            user_id = user_id,
            delivery_info_id = order_in.delivery_info_id,
            payment_method_id = order_in.payment_method_id,
            rank_discount = discount,
            status = OrderStatus.PENDING
        )
        db.add(new_order)
        db.flush() # lay ID de gan vao chi tiet

        #tao cac order detail
        for item in order_items_to_create:
            detail = OrderDetail(
                order_id = new_order.id,
                product_detail_id =item["product_detail_id"],
                quantity = item["quantity"],
                price = item["price"]
            )
            db.add(detail)
        
        #xoa gio hang sau khi dat thanh cong
        db.query(CartDetail).filter(CartDetail.cart_id == cart.id).delete()

        db.commit()
        db.refresh(new_order)
        return new_order