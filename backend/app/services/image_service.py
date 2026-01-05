from typing import List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
import cloudinary.uploader
from app.models.product import Product
from app.models.image_url import ImageURL
class ImageService:
    @staticmethod
    def add_images(db: Session, product_id: int, images: List[dict]):
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Không tìm thấy sản phẩm")
        
        db_images = []
        for img in images:
            db_image = ImageURL(
                product_id=product_id,
                url=img["url"],
                public_id=img["public_id"],
            )
            db.add(db_image)
            db_images.append(db_image)
        
        db.commit()
        for img in db_images:
            db.refresh(img)

        return db_images
    

    @staticmethod
    def delete_image(db: Session, image_id: int):
        """Xóa một ảnh cụ thể theo ID"""
        db_image = db.query(ImageURL).filter(ImageURL.id == image_id).first()
        if not db_image:
            raise HTTPException(status_code=404, detail="Không tìm thấy ảnh")
        cloudinary.uploader.destroy(db_image.public_id)
        
        db.delete(db_image)
        db.commit()
        return {"message": " Xóa ảnh thành công"}
    

    @staticmethod
    def deleteAll_image(db: Session, product_id: int):
        """Xóa toàn bộ ảnh của một sản phẩm ( dùng khi updated bộ ảnh mới)"""

        images = db.query(ImageURL).filter(ImageURL.product_id == product_id).all()

        for img in images:
            cloudinary.uploader.destroy(img.public_id)
            
        db.query(ImageURL).filter(ImageURL.product_id == product_id).delete()
        db.commit()
        return {"message": "Đã xóa toàn bộ ảnh của sản phẩm"}