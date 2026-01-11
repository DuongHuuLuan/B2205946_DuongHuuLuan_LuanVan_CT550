from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from app.models import *
from app.models.discount import OrderDiscount
from app.models.order import OrderStatus
from app.schemas import *
from app.services.warehouse_service import WarehouseService
from typing import List

class OrderService:

    @staticmethod
    def create_order(db: Session, user_id: int, order_in: OrderCreate):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart or not cart.cart_details:
            raise HTTPException(status_code=400, detail= "Giỏ hàng trống")
        
        total_price = 0
        order_items_to_create = []

        for cart_detail in cart.cart_details:
            product_detail = db.query(ProductDetail).filter(ProductDetail.id == cart_detail.product_detail_id).first()
            if not product_detail:
                raise HTTPException(
                    status_code=400,
                    detail=f"San pham ID{cart_detail.product_detail_id} khong du hang"
                )

            available_quantity = WarehouseService.get_total_stock(db, product_detail)
            if available_quantity < cart_detail.quantity:
                raise HTTPException(
                    status_code=400,
                    detail=f"San pham {product_detail.product.name} khong du hang"
                )

            #tinh tien (gia tai thoi diem mua)
            total_price += product_detail.price *cart_detail.quantity
            #chuan bi du lieu cho OrderDetail
            order_items_to_create.append({
                "product_detail_id": product_detail.id,
                "quantity": cart_detail.quantity,
                "price": product_detail.price
            })

            # tru kho
            WarehouseService.decrease_stock(db, product_detail, cart_detail.quantity)
        #tinh rank_discount
        # chổ này ví dụ đang tính là 5%
        rank_discount_amount = total_price * 0.05 

        #giảm giá theo voucher
        voucher_discount = None
        if order_in.discount_code:
            from app.services.discount_service import DiscountService
            voucher_discount = DiscountService.get_valid_discount(db,order_in.discount_code)
            if not voucher_discount:
                raise HTTPException(status_code=400, detail="Mã giảm giá không hợp lệ hoặc đã hết hạn")
            

        # tạo order header
        new_order = Order(
            user_id = user_id,
            delivery_info_id = order_in.delivery_info_id,
            payment_method_id = order_in.payment_method_id,
            rank_discount = rank_discount_amount,
            status = OrderStatus.PENDING
        )
        db.add(new_order)
        db.flush() # lay ID de gan vao chi tiet

        # luu lien ket Voucher vao bang trung gian
        if voucher_discount:
            order_discount = OrderDiscount(
                order_id = new_order.id,
                discount_id = voucher_discount.id
            )
            db.add(order_discount)

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
    

    #lấy danh sách đơn hàng của user
    @staticmethod
    def get_orders(db: Session, user_id: int, ) -> List[Order]:
        return db.query(Order).options(
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.product)
                .joinedload(Product.product_images),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.color),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.size)
            ).filter(Order.user_id == user_id).order_by(Order.created_at.desc()).all()
    
    #chi tiết một đơn hàng
    @staticmethod
    def get_order_byID(db: Session, order_id: int, user_id: int):
        order = db.query(Order).options(
            # Tương tự như trên, phải nạp đủ các bảng liên quan
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.product)
                .joinedload(Product.product_images),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.color),
            joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.size),
            joinedload(Order.delivery_info),
            joinedload(Order.payment_method)
        ).filter(Order.id == order_id, Order.user_id == user_id).first()
        
        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
        return order
    
    #cập nhật trạng thái(AMDIN)
    @staticmethod
    def update_status(db: Session, order_id: int, status: OrderStatus):
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
        
        order.status = status
        db.commit()
        db.refresh(order)
        return order
    
    # hủy đơn hàng
    @staticmethod
    def delete_order(db: Session, order_id: int, user_id: int):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()
        if not order:
            raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại")
        
        if order.status != OrderStatus.PENDING:
            raise HTTPException(status_code=400, detail="Chỉ có thể hủy đơn hàng đang chờ xử lý")
        for order_detail in order.order_details:
            WarehouseService.increase_stock(db, order_detail.product_detail, order_detail.quantity)

            
        order.status = OrderStatus.CANCELLED
        db.commit()
        return {"massage":"Hủy đơn hàng thành công"}
    

    @staticmethod
    def confirm_delivery(db: Session, order_id: int, user_id: int):
        order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).first()

        if not order:
            raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
        
        if order.status != OrderStatus.SHIPPING:
            raise HTTPException(
                status_code=400, detail="Chỉ có thể xác nhận khi đơn hàng đang trong quá trình giao hàng"
            )
        order.status = OrderStatus.COMPLETED

        db.commit()
        db.refresh(order)
        return order