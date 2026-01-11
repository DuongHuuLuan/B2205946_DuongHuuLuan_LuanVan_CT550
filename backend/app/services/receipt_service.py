from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.models import *
from app.models.receipt import ReceiptStatus
from app.schemas import *


class ReceiptService:

    @staticmethod
    def create_receipt(db: Session, receipt_in: ReceiptCreate):
        db_receipt = Receipt(
            warehouse_id=receipt_in.warehouse_id,
            distributor_id=receipt_in.distributor_id,
            status=ReceiptStatus.PENDING
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
                WarehouseDetail.size_id == item.size_id
            ).first()

            if stock:
                stock.quantity += item.quantity
            else:
                new_stock = WarehouseDetail(
                    warehouse_id=receipt.warehouse_id,
                    product_id=item.product_id,
                    color_id=item.color_id,
                    size_id=item.size_id,
                    quantity=item.quantity
                )
                db.add(new_stock)

        receipt.status = ReceiptStatus.COMPLETED
        db.commit()
        return receipt
