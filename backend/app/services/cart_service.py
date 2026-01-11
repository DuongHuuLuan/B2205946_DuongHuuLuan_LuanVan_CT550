from sqlalchemy.orm import Session, selectinload, joinedload
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *
from app.services.warehouse_service import WarehouseService


class CartService:

    @staticmethod
    def _pick_image_url(product: Product, color_id: int | None):
        """Pick image URL based on color_id when possible."""
        product_images = product.product_images or []
        exact = next((img for img in product_images if img.color_id == color_id), None)
        generic = next((img for img in product_images if img.color_id is None), None)
        chosen = exact or generic or (product_images[0] if product_images else None)
        return chosen.url if chosen else None

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

        product_detail = db.query(ProductDetail).filter(ProductDetail.id == cart_detail_in.product_detail_id).first()
        if not product_detail:
            raise HTTPException(status_code=404, detail="San pham khong ton tai")

        available_quantity = WarehouseService.get_total_stock(db, product_detail)
        if available_quantity < cart_detail_in.quantity:
            raise HTTPException(status_code=400, detail=f"Chi con {available_quantity} san pham trong kho")

        cart_detail = db.query(CartDetail).filter(
            CartDetail.cart_id == cart.id,
            CartDetail.product_detail_id == cart_detail_in.product_detail_id
        ).first()
        if cart_detail:
            new_quantity = cart_detail.quantity + cart_detail_in.quantity
            if available_quantity < new_quantity:
                raise HTTPException(status_code=400, detail="Tong so luong vuot qua ton kho")
            cart_detail.quantity = new_quantity
        else:
            cart_detail = CartDetail(
                cart_id=cart.id,
                product_detail_id=cart_detail_in.product_detail_id,
                quantity=cart_detail_in.quantity
            )
            db.add(cart_detail)

        db.commit()
        db.refresh(cart)
        return cart

    @staticmethod
    def get_cart2(db: Session, user_id: int):
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Nguoi dung khong ton tai")
        cart = user.cart.cart_details
        for cart_detail in cart:
            return cart_detail.product_detail.product.product_images
        return cart

    @staticmethod
    def get_cart(db: Session, user_id: int):
        """
        Lay thong tin gio hang + total_price
        va gan them product_id/product_name/image_url cho tung CartDetail.
        """

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
            )
            .filter(Cart.user_id == user_id)
            .first()
        )

        if not cart:
            cart = CartService.get_or_create_cart(db, user_id)
            setattr(cart, "total_price", 0)
            return cart

        total = 0

        for cart_detail in cart.cart_details:
            product_detail = cart_detail.product_detail

            price = product_detail.price or 0
            total += price * cart_detail.quantity

            product = getattr(product_detail, "product", None)
            if product:
                setattr(cart_detail, "product_id", product.id)
                setattr(cart_detail, "product_name", product.name)

                color_id = product_detail.color.id if getattr(product_detail, "color", None) else None
                setattr(cart_detail, "image_url", CartService._pick_image_url(product, color_id))
            else:
                setattr(cart_detail, "product_id", 0)
                setattr(cart_detail, "product_name", "")
                setattr(cart_detail, "image_url", None)

        setattr(cart, "total_price", float(total))
        return cart

    @staticmethod
    def update_cart_detail(db: Session, user_id: int, cart_detail_id: int, new_quantity: int):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            raise HTTPException(status_code=404, detail="Gio hang trong")

        cart_detail = db.query(CartDetail).filter(CartDetail.id == cart_detail_id, CartDetail.cart_id == cart.id).first()
        if not cart_detail:
            raise HTTPException(status_code=404, detail="Khong tim thay mon hang")

        product_detail = cart_detail.product_detail
        available_quantity = WarehouseService.get_total_stock(db, product_detail)
        if available_quantity < new_quantity:
            raise HTTPException(status_code=400, detail=f"Kho chi con {available_quantity} san pham")

        cart_detail.quantity = new_quantity
        db.commit()
        db.refresh(cart)
        return CartService.get_cart(db, user_id)

    @staticmethod
    def delete_cart_detail(db: Session, user_id: int, cart_detail_id: int):
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        cart_detail = db.query(CartDetail).filter(CartDetail.id == cart_detail_id, CartDetail.cart_id == cart.id).first()
        if not cart_detail:
            raise HTTPException(status_code=404, detail="Khong tim thay mon hang trong gio hang")

        db.delete(cart_detail)
        db.commit()
        return {"message": "Da xoa san pham khoi gio hang"}
