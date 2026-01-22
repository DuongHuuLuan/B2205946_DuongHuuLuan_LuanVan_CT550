import math
from typing import Optional
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, or_
from fastapi import HTTPException
from app.models import Receipt, ReceiptDetail, WarehouseDetail, Warehouse, Distributor, Product
from app.models.receipt import ReceiptStatus
from app.schemas import ReceiptCreate


class ReceiptService:
    @staticmethod
    def get_all(
        db: Session,
        page: int = 1,
        per_page: Optional[int] = None,
        keyword: str = None,
    ):
        query = db.query(Receipt)
        if keyword:
            query = query.join(Warehouse, Receipt.warehouse_id == Warehouse.id).join(
                Distributor, Receipt.distributor_id == Distributor.id
            ).filter(
                or_(
                    Warehouse.address.ilike(f"%{keyword}%"),
                    Distributor.name.ilike(f"%{keyword}%"),
                )
            )

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
        receipts = (
            query.options(
                joinedload(Receipt.warehouse),
                joinedload(Receipt.distributor),
            )
            .order_by(Receipt.id.desc())
            .offset(skip)
            .limit(per_page)
            .all()
        )

        receipt_ids = [r.id for r in receipts]
        counts_map = {}
        if receipt_ids:
            counts = (
                db.query(ReceiptDetail.receipt_id, func.count(ReceiptDetail.id))
                .filter(ReceiptDetail.receipt_id.in_(receipt_ids))
                .group_by(ReceiptDetail.receipt_id)
                .all()
            )
            counts_map = {rid: int(cnt or 0) for rid, cnt in counts}

        for receipt in receipts:
            setattr(receipt, "items_count", counts_map.get(receipt.id, 0))

        last_page = math.ceil(total_count / per_page)
        return {
            "items": receipts,
            "meta": {
                "total": total_count,
                "current_page": page,
                "per_page": per_page,
                "last_page": last_page,
            },
        }

    @staticmethod
    def get_by_id(db: Session, receipt_id: int):
        receipt = (
            db.query(Receipt)
            .options(
                joinedload(Receipt.warehouse),
                joinedload(Receipt.distributor),
                joinedload(Receipt.details)
                .joinedload(ReceiptDetail.product)
                .joinedload(Product.category),
                joinedload(Receipt.details)
                .joinedload(ReceiptDetail.product)
                .joinedload(Product.product_images),
                joinedload(Receipt.details)
                .joinedload(ReceiptDetail.product)
                .joinedload(Product.product_details),
                joinedload(Receipt.details).joinedload(ReceiptDetail.color),
                joinedload(Receipt.details).joinedload(ReceiptDetail.size),
            )
            .filter(Receipt.id == receipt_id)
            .first()
        )
        if not receipt:
            raise HTTPException(status_code=404, detail="Khong tim thay phieu nhap")
        return receipt

    @staticmethod
    def create_receipt(db: Session, receipt_in: ReceiptCreate):
        if not receipt_in.details:
            raise HTTPException(status_code=400, detail="Chi tiet phieu nhap trong")

        for item in receipt_in.details:
            if item.size_id is None:
                raise HTTPException(status_code=400, detail="Vui long chon size")

        db_receipt = Receipt(
            warehouse_id=receipt_in.warehouse_id,
            distributor_id=receipt_in.distributor_id,
            status=ReceiptStatus.PENDING,
        )
        db.add(db_receipt)
        db.flush()

        for item in receipt_in.details:
            detail = ReceiptDetail(receipt_id=db_receipt.id, **item.model_dump())
            db.add(detail)

        db.commit()
        db.refresh(db_receipt)
        return db_receipt

    @staticmethod
    def confirm_receipt(db: Session, receipt_id: int):
        receipt = db.query(Receipt).filter(Receipt.id == receipt_id).first()
        if not receipt or receipt.status != ReceiptStatus.PENDING:
            raise HTTPException(status_code=400, detail="Invalid receipt or already processed")

        for item in receipt.details:
            stock = db.query(WarehouseDetail).filter(
                WarehouseDetail.warehouse_id == receipt.warehouse_id,
                WarehouseDetail.product_id == item.product_id,
                WarehouseDetail.color_id == item.color_id,
                WarehouseDetail.size_id == item.size_id,
            ).first()

            if stock:
                stock.quantity += item.quantity
            else:
                new_stock = WarehouseDetail(
                    warehouse_id=receipt.warehouse_id,
                    product_id=item.product_id,
                    color_id=item.color_id,
                    size_id=item.size_id,
                    quantity=item.quantity,
                )
                db.add(new_stock)

        receipt.status = ReceiptStatus.COMPLETED
        db.commit()
        return receipt

    @staticmethod
    def cancel_receipt(db: Session, receipt_id: int):
        receipt = db.query(Receipt).filter(Receipt.id == receipt_id).first()
        if not receipt or receipt.status != ReceiptStatus.PENDING:
            raise HTTPException(status_code=400, detail="Invalid receipt or already processed")

        receipt.status = ReceiptStatus.CANCELLED
        db.commit()
        return receipt
