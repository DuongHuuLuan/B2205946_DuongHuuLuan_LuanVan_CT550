from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models import *
from app.schemas import *

class CartService:

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
    def add_to_cart(db: Session, user_id: int, item_in: CartItemCreate):
        cart = CartService.get_or_create_cart(db,user_id)

        variant = db.query(ProductDetail).filter(ProductDetail.id == item_in.product_detail_id).first()
        if not variant:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        
        if variant.stock_quantity < item_in.quantity:
            raise HTTPException(status_code=400, detail=f"Chỉ còn {variant.stock_quantity} sản phẩm trong kho")
        

        cart_item = db.query(CartDetail).filter(
            CartDetail.cart_id == cart.id,
            CartDetail.product_detail_id == item_in.product_detail_id
        ).first()
        if cart_item:
            # neu roi thi cong don so luong
            new_quantity = cart_item.quantity + item_in.quantity
            if variant.stock_quantity < new_quantity:
                raise HTTPException(status_code=400, detail=" Tổng số lượng vượt quá tồn kho")
            cart_item.quantity = new_quantity
        else:
            # nếu chưa có thì thêm mới
            cart_item = CartDetail(
                cart_id = cart.id,
                product_detail_id = item_in.product_detail_id,
                quantity = item_in.quantity
            )
            db.add(cart_item)
        
        db.commit()
        db.refresh(cart)
        return cart
    
    @staticmethod
    def get_cart(db: Session, user_id: int):
        """Lấy thông tin giỏ hàng và tính tổng tiền"""
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            return CartService.get_or_create_cart(db,user_id)
        
        total = 0
        for item in cart.items:
            # lay gia tu bien the
            price = item.product_variant.price if item.product_variant.price else 0
            total += price * item.quantity
        
        setattr(cart, 'total_price', total)
        return cart
    

    @staticmethod
    def update_cart_item(db: Session, user_id: int,item_id: int, new_quantity: int):
        """Cập nhật số lượng của một item cụ thể trong giỏ hàng"""
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        if not cart:
            raise HTTPException(status_code=404, detail="Giỏ hàng trống")
        
        item = db.query(CartDetail).filter(CartDetail.id == item_id, CartDetail.cart_id == cart.id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Không tìm thấy món hàng")
        
        variant = item.product_variant
        if variant.stock_quantity < new_quantity:
            raise HTTPException(status_code=400, detail=f"Kho chỉ còn {variant.stock_quantity} Sản phẩm")
        item.quantity = new_quantity
        db.commit()
        db.refresh(cart)

        return CartService.get_cart(db, user_id)

    @staticmethod
    def delete_item_cart(db: Session, user_id: int, item_id: int):
        """Xoa mot item khoi gio"""
        cart = db.query(Cart).filter(Cart.user_id == user_id).first()
        item = db.query(CartDetail).filter(CartDetail.id == item_id, CartDetail.cart_id == cart.id).first()
        if not item:
            raise HTTPException(status_code=404, detail=" Không tìm thấy món hàng trong giỏ hàng")
        
        db.delete(item)
        db.commit()
        return {"message": "Đã xóa sản phẩm khỏi giỏ hàng"}