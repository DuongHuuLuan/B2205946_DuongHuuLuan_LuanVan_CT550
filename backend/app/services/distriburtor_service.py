import math
from typing import Optional
from sqlalchemy.orm import Session  
from app.models import *
from fastapi import HTTPException, status
from app.schemas.distributor import DistributorCreate

class DistributorService:
    @staticmethod
    def create_distributor(db: Session, distributor_in: DistributorCreate):
        db_distributor = Distributor (**distributor_in.model_dump())
        db.add(db_distributor)
        db.commit()
        db.refresh(db_distributor)
        return db_distributor
    
    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None
    ):
        query = db.query(Distributor)

        if keyword:
            query = query.filter(Distributor.name.ilike(f"%{keyword}%"))

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
            query.order_by(Distributor.id.desc()).offset(skip).limit(per_page).all()
        )
        last_page = math.ceil(total_count / per_page)

        return {
            "items": items,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page
            },
        }
    
    @staticmethod
    def get_id(db: Session, distributor_id: int):
        distributor = db.query(Distributor).filter(Distributor.id == distributor_id).first()
        if not distributor:
            raise HTTPException(status_code=404, detail="Nhà cung cấp không tồn tại")
        db.commit()
        db.refresh(distributor)
        return distributor
    
    @staticmethod
    def update_distributor(db: Session, distributor_id: int, distributor_in: DistributorCreate):
        distributor = DistributorService.get_id(db, distributor_id)

        update_data = distributor_in.model_dump(exclude_unset=True)

        for key, value in update_data.items():
            setattr(distributor,key, value)

        db.commit()
        db.refresh(distributor)
        return distributor
    

    @staticmethod
    def delete_distributor(db: Session, distributor_id: int):
        distributor = DistributorService.get_id(db, distributor_id)

        db.delete(distributor)
        db.commit()
        return {"message":"Xóa thành công nhà cung cấp"}
        
        
