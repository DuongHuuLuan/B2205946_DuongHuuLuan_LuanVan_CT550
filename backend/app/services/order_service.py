import math
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_
from fastapi import HTTPException, status
from app.models import *
from app.models.discount import OrderDiscount
from app.models.order import OrderStatus
from app.schemas import *
from app.services.warehouse_service import WarehouseService
from typing import List, Optional
from decimal import Decimal, ROUND_HALF_UP

class OrderService:

    @staticmethod
    def create_order(db: Session, user_id: int, order_in: OrderCreate):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart or not cart.cart_details:
            raise HTTPException(status_code=400, detail= "Giỏ hàng trống")
        
        total_price = Decimal("0") # tổng tiền đơn hàng
        order_details_to_create = [] # danh sách chứa chi tiết đơn hàng
        cart_details = [] # danh sách các item sẽ được xử lý
        requested_items = None # lưu giữ ID và số lượng nếu người dùng chọn mua lẻ các sản phẩm trong giỏ hàng
        selected_cart_details = cart.cart_details # mặc định là chọn toàn bộ giỏ hàng

        #logic chọn mua các sản phẩm cụ thể
        if order_in.order_items is not None:
            if not order_in.order_items:
                raise HTTPException(status_code=400, detail="Danh sách mua không được rỗng")
            requested_items = {}
            for order_item in order_in.order_items:
                if order_item.quantity <= 0:
                    raise HTTPException(status_code=400, detail="Số lượng mua phải lớn hơn 0")
                if order_item.product_detail_id in requested_items:
                    raise HTTPException(status_code=400, detail="Trùng sản phẩm trong danh sách mua")
                requested_items[order_item.product_detail_id] = order_item.quantity

            selected_cart_details = [
                cart_detail
                for cart_detail in cart.cart_details
                if cart_detail.product_detail_id in requested_items
            ]
            missing_items = set(requested_items.keys()) - {
                cart_detail.product_detail_id for cart_detail in selected_cart_details
            }
            if missing_items:
                raise HTTPException(status_code=400, detail="Sản phẩm không có trong giỏ hàng")

        for cart_detail in selected_cart_details:
            product_detail = db.query(ProductDetail).filter(ProductDetail.id == cart_detail.product_detail_id).first()
            if not product_detail:
                raise HTTPException(
                    status_code=400,
                    detail=f"Sản phẩm ID{cart_detail.product_detail_id} không đủ hàng"
                )

            available_quantity = WarehouseService.get_total_stock(db, product_detail)
            requested_quantity = cart_detail.quantity
            if requested_items:
                requested_quantity = requested_items[cart_detail.product_detail_id]
                if requested_quantity > cart_detail.quantity:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Số lượng mua vượt quá số lượng trong giỏ hàng: {product_detail.product.name}"
                    )
            if available_quantity < requested_quantity:
                raise HTTPException(
                    status_code=400,
                    detail=f"Sản phẩm {product_detail.product.name} không đủ hàng"
                )

            cart_details.append((cart_detail, product_detail, requested_quantity))

            # tru kho
            WarehouseService.decrease_stock(db, product_detail, requested_quantity)

        category_ids = {
            product_detail.product.category_id
            for _, product_detail, _ in cart_details
            if product_detail.product and product_detail.product.category_id
        }
        from app.services.discount_service import DiscountService
        category_discounts = DiscountService.get_valid_discounts_by_category_ids(
            db,
            category_ids,
        )

        for cart_detail, product_detail, requested_quantity in cart_details:
            unit_price = Decimal(str(product_detail.price or 0))
            discount = None
            if product_detail.product:
                discount = category_discounts.get(product_detail.product.category_id)

            discounted_unit_price = unit_price
            if discount:
                percent = Decimal(str(discount.percent))
                discount_multiplier = (Decimal("100") - percent) / Decimal("100")
                discounted_unit_price = (unit_price * discount_multiplier).quantize(
                    Decimal("0.01"),
                    rounding=ROUND_HALF_UP,
                )

            total_price += discounted_unit_price * requested_quantity
            order_details_to_create.append({
                "product_detail_id": product_detail.id,
                "quantity": requested_quantity,
                "price": discounted_unit_price,
            })

        # tạo order header
        new_order = Order(
            user_id = user_id,
            delivery_info_id = order_in.delivery_info_id,
            payment_method_id = order_in.payment_method_id,
            status = OrderStatus.PENDING
        )
        db.add(new_order)
        db.flush() # lay ID de gan vao chi tiet

        #tao cac order detail
        for order_detail in order_details_to_create:
            detail = OrderDetail(
                order_id = new_order.id,
                product_detail_id =order_detail["product_detail_id"],
                quantity = order_detail["quantity"],
                price = order_detail["price"]
            )
            db.add(detail)
        
        #xoa gio hang sau khi dat thanh cong
        if requested_items:
            for cart_detail, _, requested_quantity in cart_details:
                if requested_quantity < cart_detail.quantity:
                    cart_detail.quantity = cart_detail.quantity - requested_quantity
                else:
                    db.delete(cart_detail)
        else:
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
    

    def get_orders2(db: Session, user_id: int) -> List[Order]:
        return db.query(Order).filter(Order.user_id == user_id).all()

    #chi tiết một đơn hàng
    @staticmethod
    def get_order_byID(db: Session, order_id: int, user_id: int):
        order = db.query(Order).options(
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
    
    @staticmethod
    def get_admin_orders(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: Optional[str] = None,
        status: Optional[str] = None,
    ):
        query = db.query(Order)

        if keyword:
            like = f"%{keyword}%"
            conditions = [User.email.ilike(like), User.username.ilike(like)]
            if keyword.isdigit():
                conditions.append(Order.id == int(keyword))
            query = query.join(User, Order.user_id == User.id).filter(or_(*conditions))

        if status:
            try:
                status_value = OrderStatus(status.strip().lower())
            except ValueError as exc:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Trạng thái không hợp lệ",
                ) from exc
            query = query.filter(Order.status == status_value)

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
            query.options(
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
                joinedload(Order.payment_method),
                joinedload(Order.user),
            )
            .order_by(Order.created_at.desc())
            .offset(skip)
            .limit(per_page)
            .all()
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
    def get_admin_order_by_id(db: Session, order_id: int):
        order = (
            db.query(Order)
            .options(
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
                joinedload(Order.payment_method),
                joinedload(Order.user),
            )
            .filter(Order.id == order_id)
            .first()
        )

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
