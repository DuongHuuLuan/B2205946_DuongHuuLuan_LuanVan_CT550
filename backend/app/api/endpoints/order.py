from io import BytesIO
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import *
from app.schemas import *
from app.schemas.order import OrderRejectIn, OrderStatusUpdate
from app.services.order_service import OrderService
from app.services.production_export_service import ProductionExportService
from app.api.deps import require_user, require_admin


router = APIRouter(prefix="/orders", tags=["Order"])

@router.post("/", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    order_in: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """API thực hiện đặt hàng từ giỏ hàng của người dùng"""
    return OrderService.create_order(db=db,user_id=current_user.id,order_in=order_in)

    ##ADMIN
@router.get("/", response_model=OrderPaginationOut)
def get_admin_orders(
    page: int = 1,
    per_page: Optional[int] = None,
    q: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API lấy tất cả đơn hàng"""
    return OrderService.get_admin_orders(
        db=db,
        page=page,
        per_page=per_page,
        keyword=q,
        status_filter=status,
    )

@router.get("/admin/{order_id}", response_model=OrderOut)
def get_admin_order_detail(
    order_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """API lấy đơn hàng cụ thể theo ID"""
    return OrderService.get_admin_order_by_id(db=db, order_id=order_id)

@router.get("/admin/{order_id}/production", response_model=OrderProductionOut)
def get_order_production(
    order_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return ProductionExportService.get_order_production(db=db, order_id=order_id)


@router.get("/admin/{order_id}/production/export")
def export_order_production(
    order_id: int,
    format: str = Query(default="pdf", pattern="^(pdf|svg)$"),
    dpi: int = Query(default=300, ge=72, le=600),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    file_bytes, media_type, filename = ProductionExportService.export_order(
        db=db,
        order_id=order_id,
        export_format=format,
        dpi=dpi,
    )
    return StreamingResponse(
        BytesIO(file_bytes),
        media_type=media_type,
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )

@router.get("/history", response_model=List[OrderOut])
def get_order_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """Lấy danh sách tất cả đơn hàng đã mua của người dùng hiện tại"""
    orders = OrderService.get_orders(db=db, user_id=current_user.id)
    return orders
@router.get("/history2", response_model=List[OrderOut])
def get_order_history_legacy(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """Lấy danh sách tất cả đơn hàng đã mua của người dùng hiện tại"""
    orders = OrderService.get_orders2(db=db, user_id=current_user.id)
    return orders

@router.get("/{order_id}", response_model=OrderOut)
def get_order_details(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Xem chi tiết một đơn hàng cụ thể bằng ID.
    """
    return OrderService.get_order_byID(db=db, order_id=order_id, user_id=current_user.id)

# --- ENDPOINT 4: HỦY ĐƠN HÀNG ---
@router.post("/{order_id}/cancel")
def cancel_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Hủy đơn hàng (chỉ áp dụng khi đơn ở trạng thái PENDING).
    """
    return OrderService.delete_order(db=db, order_id=order_id, user_id=current_user.id)

@router.put("/{order_id}/status", response_model=OrderOut)
def update_status(
    order_id: int,
    status_data: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    """
    Cập nhật trạng thái đơn hàng (ADMIN)
    các trạng thái pending, shipping,completed, cancelled
    """
    return OrderService.update_status(
        db=db, order_id=order_id, status=status_data.status
    )


@router.post("/{order_id}/approve", response_model=OrderOut)
def approve_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return OrderService.approve_order(
        db=db,
        order_id=order_id,
        admin_id=current_admin.id,
    )


@router.post("/{order_id}/reject", response_model=OrderOut)
def reject_order(
    order_id: int,
    payload: OrderRejectIn,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return OrderService.reject_order(
        db=db,
        order_id=order_id,
        admin_id=current_admin.id,
        reason=payload.reason,
    )

@router.post("/{order_id}/confirm-delivery", response_model=OrderOut)
def confirm_delivery(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    """
    Người dùng xác nhận đã nhận hàng thành công
    """
    return OrderService.confirm_delivery(
        db=db,
        order_id=order_id,
        user_id=current_user.id
    )
