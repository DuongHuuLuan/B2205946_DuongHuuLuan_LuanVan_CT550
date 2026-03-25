from sqlalchemy.orm import Session, selectinload, joinedload
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *
from app.services.warehouse_service import WarehouseService
from app.services.base import BaseService
from app.services.image_service import ImageService


class CartService(BaseService):

    @staticmethod
    def _pick_image_url(product: Product, color_id: int | None):
        """Pick image URL based on color_id when possible."""
        chosen = ImageService.pick_primary_image(
            list(product.product_images or []),
            color_id=color_id,
        )
        return chosen.url if chosen else None

    @staticmethod
    def _normalize_design_id(design_id: int | None) -> int | None:
        if design_id is None or design_id <= 0:
            return None
        return design_id


# Hàm kiểm tra thiết kế hợp lệ
    @staticmethod
    def _validate_design(
        db: Session,
        user_id: int,
        product_detail: ProductDetail,
        design_id: int | None,
    ) -> Design | None:
        normalized_design_id = CartService._normalize_design_id(design_id)
        if normalized_design_id is None:
            return None

        design = CartService.get_or_404(db, Design, normalized_design_id, "Thiết kế không tồn tại")
        CartService.assert_owner(user_id, design.user_id, "Bạn không có quyền dùng thiết kế này")
        if design.product_id != product_detail.product_id:
            raise HTTPException(
                status_code=400,
                detail="Thiết kế không thuộc biến thể sản phẩm đã chọn",
            )
        return design


#Hàm tìm sản phẩm đã có trong giỏ
    @staticmethod
    def _find_existing_cart_detail(
        db: Session,
        cart_id: int,
        product_detail_id: int,
        design_id: int | None,
    ):
        query = db.query(CartDetail).filter(
            CartDetail.cart_id == cart_id,
            CartDetail.product_detail_id == product_detail_id,
        )
        if design_id is None:
            query = query.filter(CartDetail.design_id.is_(None))
        else:
            query = query.filter(CartDetail.design_id == design_id)
        return query.first()

    @staticmethod
    def _attach_cart_detail_metadata(cart_detail: CartDetail):
        product_detail = cart_detail.product_detail
        product = getattr(product_detail, "product", None) if product_detail else None
        if product:
            setattr(cart_detail, "product_id", product.id)
            setattr(cart_detail, "product_name", product.name)

            color_id = product_detail.color.id if getattr(product_detail, "color", None) else None
            setattr(cart_detail, "image_url", CartService._pick_image_url(product, color_id))
        else:
            setattr(cart_detail, "product_id", 0)
            setattr(cart_detail, "product_name", "")
            setattr(cart_detail, "image_url", None)

        design = getattr(cart_detail, "design", None)
        setattr(cart_detail, "design_name", getattr(design, "name", None))
        setattr(
            cart_detail,
            "design_preview_image_url",
            getattr(design, "preview_image_url", None),
        )

    @staticmethod
    def _resolve_cart_status(product_detail: ProductDetail, available_stock: int, quantity: int):
        if not product_detail.is_active:
            return {
                "is_active": False,
                "available_stock": available_stock,
                "cart_status": "inactive",
                "status_message": "Sản phẩm đã ngừng bán",
                "can_checkout": False,
            }

        if available_stock <= 0:
            return {
                "is_active": True,
                "available_stock": 0,
                "cart_status": "out_of_stock",
                "status_message": "Sản phẩm đã hết hàng",
                "can_checkout": False,
            }

        if quantity > available_stock:
            return {
                "is_active": True,
                "available_stock": available_stock,
                "cart_status": "insufficient_stock",
                "status_message": f"Chỉ còn {available_stock} sản phẩm trong kho",
                "can_checkout": False,
            }

        return {
            "is_active": True,
            "available_stock": available_stock,
            "cart_status": "ok",
            "status_message": None,
            "can_checkout": True,
        }


    @staticmethod
    def _attach_cart_detail_status(db: Session, cart_detail: CartDetail):
        product_detail = cart_detail.product_detail
        available_quantity = WarehouseService.get_total_stock(db, product_detail)

        status_data = CartService._resolve_cart_status(
            product_detail=product_detail,
            available_stock=available_quantity,
            quantity=cart_detail.quantity,
        )

        setattr(cart_detail, "is_active", status_data["is_active"])
        setattr(cart_detail, "available_stock", status_data["available_stock"])
        setattr(cart_detail, "cart_status", status_data["cart_status"])
        setattr(cart_detail, "status_message", status_data["status_message"])
        setattr(cart_detail, "can_checkout", status_data["can_checkout"])    

    @staticmethod
    def get_or_create_cart(db: Session, user_id: int):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            cart = Cart(user_id=user_id)
            db.add(cart)
            db.commit()
            db.refresh(cart)
        return cart

    @staticmethod
    def add_to_cart(db: Session, user_id: int, cart_detail_in: CartDetailCreate):
        cart = CartService.get_or_create_cart(db, user_id)

        # Kiểm tra sản phẩm có tồn tại không
        product_detail = CartService.get_or_404(db, ProductDetail, cart_detail_in.product_detail_id, "Sản phẩm không tồn tại")

        if not product_detail.is_active:
            raise HTTPException(
        status_code=400,
        detail="Biến thể sản phẩm đã ngừng bán"
    )
        
        design = CartService._validate_design(
            db,
            user_id,
            product_detail,
            cart_detail_in.design_id,
        )
        design_id = getattr(design, "id", None)

        # Kiểm tra tồn kho
        available_quantity = WarehouseService.get_total_stock(db, product_detail)
        if available_quantity < cart_detail_in.quantity:
            raise HTTPException(status_code=400, detail=f"Chỉ còn {available_quantity} sản phẩm trong kho")

        cart_detail = CartService._find_existing_cart_detail(
            db,
            cart.id,
            cart_detail_in.product_detail_id,
            design_id,
        )

        if cart_detail:
            new_quantity = cart_detail.quantity + cart_detail_in.quantity
            if available_quantity < new_quantity:
                raise HTTPException(status_code=400, detail="Tổng số lượng vượt quá tồn kho")
            cart_detail.quantity = new_quantity
        else:
            cart_detail = CartDetail(
                cart_id=cart.id,
                product_detail_id=cart_detail_in.product_detail_id,
                design_id=design_id,
                quantity=cart_detail_in.quantity
            )
            db.add(cart_detail)

        db.commit()
        db.refresh(cart)
        return CartService.get_cart(db, user_id)

    @staticmethod
    def get_cart2(db: Session, user_id: int):
        user = CartService.get_or_404(db, User, user_id, "Người dùng không tồn tại")
        cart = user.cart.cart_details
        for cart_detail in cart:
            return cart_detail.product_detail.product.product_images
        return cart

    @staticmethod
    def get_cart(db: Session, user_id: int):

        cart = (
            db.query(Cart)
            .options(
                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.color),

                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.size),

                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.product)
                    .selectinload(Product.product_images),

                selectinload(Cart.cart_details).joinedload(CartDetail.design),
            )
            .filter(Cart.user_id == user_id)
            .first()
        )

        if not cart:
            cart = CartService.get_or_create_cart(db, user_id)
            setattr(cart, "total_price", 0)
            setattr(cart, "can_checkout", True)
            return cart

        total = 0
        can_checkout = True

        for cart_detail in cart.cart_details:
            product_detail = cart_detail.product_detail

            price = product_detail.price or 0
            total += price * cart_detail.quantity

            CartService._attach_cart_detail_metadata(cart_detail)
            CartService._attach_cart_detail_status(db, cart_detail)
            
            if not getattr(cart_detail, "can_checkout", True):
                can_checkout = False

            CartService._attach_cart_detail_metadata(cart_detail)

        setattr(cart, "total_price", float(total))
        setattr(cart, "can_checkout", can_checkout)
        return cart

    @staticmethod
    def update_cart_detail(db: Session, user_id: int, cart_detail_id: int, new_quantity: int):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")

        cart_detail = db.query(CartDetail).filter(CartDetail.id == cart_detail_id, CartDetail.cart_id == cart.id).first()
        if not cart_detail:
            raise HTTPException(status_code=404, detail="Không tìm thấy giỏ hàng")

        product_detail = cart_detail.product_detail
        if not product_detail.is_active:
            raise HTTPException(
                status_code=400,
                detail="Sản phẩm trong giỏ đã ngừng bán, vui lòng xóa khỏi giỏ hàng"
                )
        available_quantity = WarehouseService.get_total_stock(db, product_detail)
        if available_quantity < new_quantity:
            raise HTTPException(status_code=400, detail=f"Kho chỉ còn {available_quantity} sản phẩm")

        cart_detail.quantity = new_quantity
        db.commit()
        db.refresh(cart)
        return CartService.get_cart(db, user_id)

    @staticmethod
    def delete_cart_detail(db: Session, user_id: int, cart_detail_id: int):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        cart_detail = CartService.get_or_404(db, CartDetail, cart_detail_id, "Không tìm thấy món hàng trong giỏ hàng")

        db.delete(cart_detail)
        db.commit()
        return {"message": "Đã xóa sản phẩm khỏi giỏ hàng"}
