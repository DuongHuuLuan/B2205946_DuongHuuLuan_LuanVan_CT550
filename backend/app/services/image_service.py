from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, UploadFile, status
import cloudinary.uploader
from app.models.product import Product
from app.models.image_url import ImageURL
class ImageService:
    @staticmethod
    def _pick_primary_from_bucket(images: List[ImageURL]) -> Optional[ImageURL]:
        if not images:
            return None

        front = next(
            (
                image
                for image in images
                if str(getattr(image, "view_image_key", "") or "").strip() == "front-left"
            ),
            None,
        )
        if front:
            return front

        generic = next(
            (
                image
                for image in images
                if not str(getattr(image, "view_image_key", "") or "").strip()
            ),
            None,
        )
        return generic or images[0]

    @staticmethod
    def pick_primary_image(
        images: List[ImageURL],
        color_id: Optional[int] = None,
    ) -> Optional[ImageURL]:
        items = list(images or [])
        if not items:
            return None

        by_color = [image for image in items if getattr(image, "color_id", None) == color_id]
        if by_color:
            return ImageService._pick_primary_from_bucket(by_color)

        commons = [image for image in items if getattr(image, "color_id", None) is None]
        if commons:
            return ImageService._pick_primary_from_bucket(commons)

        return ImageService._pick_primary_from_bucket(items)

    @staticmethod
    def add_images(db: Session, product_id: int, images: List[dict]):
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Không tìm thấy sản phẩm")
        
        db_images = []
        for img in images:
            db_image = ImageURL(
                product_id=product_id,
                color_id =img.get("color_id"),
                url=img["url"],
                public_id=img["public_id"],
                view_image_key=img.get("view_image_key"),
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

    @staticmethod
    def replace_image(
        db: Session,
        image_id: int,
        new_file: UploadFile,
        product_id: Optional[int] = None,
    ):
        query = db.query(ImageURL).filter(ImageURL.id == image_id)
        if product_id is not None:
            query = query.filter(ImageURL.product_id == product_id)
        db_image = query.first()
        if not db_image:
            raise HTTPException(status_code=404, detail="Image not found")

        old_public_id = db_image.public_id
        result = cloudinary.uploader.upload(
            new_file.file,
            folder="helmet_shop/products",
        )

        db_image.url = result["secure_url"]
        db_image.public_id = result["public_id"]
        db.commit()
        db.refresh(db_image)

        if old_public_id:
            cloudinary.uploader.destroy(old_public_id)

        return db_image

    @staticmethod
    def update_view_image_key(
        db: Session,
        image_id: int,
        view_image_key: Optional[str],
        product_id: Optional[int] = None,
    ):
        query = db.query(ImageURL).filter(ImageURL.id == image_id)
        if product_id is not None:
            query = query.filter(ImageURL.product_id == product_id)
        db_image = query.first()
        if not db_image:
            raise HTTPException(status_code=404, detail="Image not found")

        db_image.view_image_key = view_image_key
        db.commit()
        db.refresh(db_image)
        return db_image
