from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status
from app.models.product import Product
from app.models.category import Category
from app.schemas.product import ProductCreated

class ProductService:
    @staticmethod
    def create_product(db: Session, product_in: ProductCreated):
        category = db.query(Category).filter(Category.id == product_in.category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục này")
        # product_in.model_dump sẽ lấy tất cả trường: name, description, unit, category_id
        db_product = Product(**product_in.model_dump())
        
        db.add(db_product)
        db.commit()
        db.refresh(db_product)
        return db_product


    @staticmethod
    def getAll_product(db: Session):
        return db.query(Product).all()

    @staticmethod
    def get_product_byID(db: Session, product_id: int):
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        return product 
    
## hàm lấy tất cả sản phẩm theo danh mục
    @staticmethod
    def get_product_category(db: Session, category_id: int):
        products = db.query(Product).filter(Product.category_id == category_id).options(joinedload(Product.category), joinedload(Product.images)).all()
        if not products:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục sản phẩm")
        return products

    @staticmethod
    def update_product(db: Session, product_id: int, product_in: ProductCreated):
        db_product = db.query(Product).filter(Product.id == product_id).first()
        if not db_product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")

        update_data = product_in.dict(exclude_unset=True)   ## chỉ lấy những trường có gửi dữ liệu
        for key, value in update_data.items():
            setattr(db_product, key, value)

        
        db.commit()
        db.refresh(db_product)
        return db_product
    
    @staticmethod
    def delete_product(db: Session, product_id: int):
        db_product = db.query(Product).filter(Product.id == product_id).first()
        if not db_product:
            raise HTTPException(status_code=404, detail="Sản phẩm không tồn tại")
        
        db.delete(db_product)
        db.commit()
        return  {"message": "Đã chuyển sản phẩm vào thùng rác"}