from sqlalchemy.orm import Session, selectinload, joinedload
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *

class CartService:

    @staticmethod
    def _pick_image_url(product: Product, color_id: int | None):
        """Lấy URL ảnh dựa trên color_id nếu có, nếu không trả về ảnh đầu tiên"""
        product_images = product.product_images or []
        exact = next((img for img in product_images if img.color_id == color_id), None)
        generic = next((img for img in product_images if img.color_id is None), None)
        chosen = exact or generic or (product_images[0] if product_images else None)
        return chosen.url if chosen else None
        

    @staticmethod
    def get_or_create_cart(db: Session, user_id: int):
        """lay gio hang cua user, neu chua co thi tao moi"""
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            cart = Cart(user_id = user_id)
            db.add(cart)
            db.commit()
            db.refresh(cart)
        return cart
    

    @staticmethod
    def add_to_cart(db: Session, user_id: int, item_in: CartDetailCreate):
        cart = CartService.get_or_create_cart(db,user_id)

        product_detail = db.query(ProductDetail).filter(ProductDetail.id == item_in.product_detail_id).first()
        if not product_detail:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        
        if product_detail.stock_quantity < item_in.quantity:
            raise HTTPException(status_code=400, detail=f"Chỉ còn {product_detail.stock_quantity} sản phẩm trong kho")
        

        cart_detail = db.query(CartDetail).filter(
            CartDetail.cart_id == cart.id,
            CartDetail.product_detail_id == item_in.product_detail_id
        ).first()
        if cart_detail:
            # neu roi thi cong don so luong
            new_quantity = cart_detail.quantity + item_in.quantity
            if product_detail.stock_quantity < new_quantity:
                raise HTTPException(status_code=400, detail=" Tổng số lượng vượt quá tồn kho")
            cart_detail.quantity = new_quantity
        else:
            # nếu chưa có thì thêm mới
            cart_detail = CartDetail(
                cart_id = cart.id,
                product_detail_id = item_in.product_detail_id,
                quantity = item_in.quantity
            )
            db.add(cart_detail)
        
        db.commit()
        db.refresh(cart)
        return cart
    
    @staticmethod
    def get_cart2(db: Session, user_id: int):
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Người dùng không tồn tại")
        cart = user.cart.cart_details
        for cart_detail in cart:
            return cart_detail.product_detail.product.product_images
        print(cart)
        return cart
    
    @staticmethod
    def get_cart(db, user_id: int):
        """
        Lấy thông tin giỏ hàng + tính total_price
        và gắn thêm product_id/product_name/image_url cho mỗi CartDetail
        để match CartItemOut mới.
        """

        cart = (
            db.query(Cart)
            .options(
                # Load items + variant
                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.color),

                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.size),

                # Load product + images
                selectinload(Cart.cart_details)
                    .joinedload(CartDetail.product_detail)
                    .joinedload(ProductDetail.product)
                    .selectinload(Product.product_images),
            )
            .filter(Cart.user_id == user_id)
            .first()
        )

        # Nếu chưa có cart -> tạo mới
        if not cart:
            cart = CartService.get_or_create_cart(db, user_id)
            setattr(cart, "total_price", 0)
            return cart

        total = 0

        for cart_detail in cart.cart_details:
            product_detail = cart_detail.product_detail

            # Tính tiền
            price = product_detail.price or 0
            total += price * cart_detail.quantity

            # ===== Gắn thêm các field theo schema CartItemOut =====
            # product_id, product_name, image_url lấy từ variant.product
            product = getattr(product_detail, "product", None)
            if product:
                setattr(cart_detail, "product_id", product.id)
                setattr(cart_detail, "product_name", product.name)

                # ưu tiên color_id từ variant.color (đã joinedload)
                color_id = product_detail.color.id if getattr(product_detail, "color", None) else None
                setattr(cart_detail, "image_url", CartService._pick_image_url(product, color_id))
            else:
                # fallback để không bị thiếu field
                setattr(cart_detail, "product_id", 0)
                setattr(cart_detail, "product_name", "")
                setattr(cart_detail, "image_url", None)

        setattr(cart, "total_price", float(total))
        return cart
    

    @staticmethod
    def update_cart_item(db: Session, user_id: int,item_id: int, new_quantity: int):
        """Cập nhật số lượng của một item cụ thể trong giỏ hàng"""
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")
        
        cart_detail = db.query(CartDetail).filter(CartDetail.id == item_id, CartDetail.cart_id == cart.id).first()
        if not cart_detail:
            raise HTTPException(status_code=404, detail="Không tìm thấy món hàng")
        
        product_detail = cart_detail.product_detail
        if product_detail.stock_quantity < new_quantity:
            raise HTTPException(status_code=400, detail=f"Kho chỉ còn {product_detail.stock_quantity} Sản phẩm")
        cart_detail.quantity = new_quantity
        db.commit()
        db.refresh(cart)

        return CartService.get_cart(db, user_id)

    @staticmethod
    def delete_item_cart(db: Session, user_id: int, item_id: int):
        """Xoa mot item khoi gio"""
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        cart_detail = db.query(CartDetail).filter(CartDetail.id == item_id, CartDetail.cart_id == cart.id).first()
        if not cart_detail:
            raise HTTPException(status_code=404, detail=" Không tìm thấy món hàng trong giỏ hàng")
        
        db.delete(cart_detail)
        db.commit()
        return {"message": "Đã xóa sản phẩm khỏi giỏ hàng"}