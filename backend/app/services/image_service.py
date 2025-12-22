from typing import List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.product import Product
from app.models.image_url import ImageURL
class ImageService:
    @staticmethod
    def add_images(db: Session, product_id: int, image_urls: List[str]):
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Không tìm thấy sản phẩm")
        
        new_images = []
        for url in image_urls:
            db_image = ImageURL(product_id = product_id, url=url)
            db.add(db_image)
            new_images.append(db_image)
        
        db.commit()
        for img in new_images:
            db.refresh(db_image)

        return new_images
    

    @staticmethod
    def delete_image(db: Session, image_id: int):
        """Xóa một ảnh cụ thể theo ID"""
        db_image = db.query(ImageURL).filter(ImageURL.id == image_id).first()
        if not db_image:
            raise HTTPException(status_code=404, detail="Không tìm thấy ảnh")
        
        db.delete(db_image)
        db.commit()
        return {"message": " Xóa ảnh thành công"}
    

    @staticmethod
    def deleteAll_image(db: Session, product_id: int):
        """Xóa toàn bộ ảnh của một sản phẩm ( dùng khi updated bộ ảnh mới)"""

        db.query(ImageURL).filter(ImageURL.product_id == product_id).delete()
        db.commit()
        return {"message": "Đã xóa toàn bộ ảnh của sản phẩm"}