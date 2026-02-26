import os
import shutil
import uuid
from pathlib import Path
from typing import List, Optional

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from fastapi.params import Query
from sqlalchemy.orm import Session

from app.api.deps import require_admin, require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.evaluate import (
    EvaluateOut,
    EvaluateReplyCreate,
    EvaluatePaginationOut,
    EvaluateProductPaginationOut,
)
from app.services.evaluate_service import EvaluateService


router = APIRouter(prefix="/evaluates", tags=["Evaluates"])

MAX_EVALUATE_IMAGES = 5
BACKEND_DIR = Path(__file__).resolve().parents[3]
UPLOAD_DIR = BACKEND_DIR / "static" / "evaluates"


def _save_upload_image(image: UploadFile) -> str:
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    ext = os.path.splitext(image.filename or "")[1]
    file_name = f"{uuid.uuid4()}{ext}"
    file_path = UPLOAD_DIR / file_name

    with file_path.open("wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    return f"/static/evaluates/{file_name}"

@router.get("/admin", response_model=EvaluatePaginationOut)
def get_admin_evaluations(
    page: int = Query(1, ge=1),
    per_page: int = Query(8, ge=1, le=100),
    has_reply: Optional[bool] = Query(None),
    order_id: Optional[int] = Query(None, ge=1),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return EvaluateService.get_admin_evaluations(
        db=db,
        page=page,
        per_page=per_page,
        has_reply=has_reply,
        order_id=order_id,
    )

@router.get("/my", response_model=EvaluatePaginationOut)
def get_my_evaluations(
    page: int = Query(1, ge=1),
    per_page: int = Query(8, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return EvaluateService.get_my_evaluations(
        db=db,
        user_id=current_user.id,
        page=page,
        per_page=per_page,
    )

@router.get("/order/{order_id}", response_model=EvaluateOut)
def get_evaluate_by_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return EvaluateService.get_evaluation_by_order(
        db=db,
        order_id=order_id,
        current_user=current_user,
    )

@router.get("/product/{product_id}", response_model=EvaluateProductPaginationOut)
def get_product_evaluations(
    product_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(3, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return EvaluateService.get_product_evaluations(
        db=db,
        product_id=product_id,
        page=page,
        per_page=per_page,
    )

@router.get("/{evaluate_id}", response_model=EvaluateOut)
def get_evaluate_detail(
    evaluate_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return EvaluateService.get_evaluation_by_id(
        db=db,
        evaluate_id=evaluate_id,
        current_user=current_user,
    )

@router.post("/{order_id}", response_model=EvaluateOut, status_code=status.HTTP_201_CREATED)
async def post_evaluate(
    order_id: int,
    rate: int = Form(..., ge=1, le=5),
    content: Optional[str] = Form(None),
    images: Optional[List[UploadFile]] = File(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    uploaded_images = images or []

    if len(uploaded_images) > MAX_EVALUATE_IMAGES:
        raise HTTPException(status_code=400, detail=f"Chỉ được tải tối đa {MAX_EVALUATE_IMAGES} ảnh")

    image_urls: List[str] = []
    for image in uploaded_images:
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Tất cả file tải lên phải là ảnh")
        image_urls.append(_save_upload_image(image))

    return EvaluateService.create_evaluation(
        db=db,
        user_id=current_user.id,
        order_id=order_id,
        rate=rate,
        content=content,
        image_urls=image_urls,
    )


@router.post("/{evaluate_id}/reply", response_model=EvaluateOut)
def reply_evaluate(
    evaluate_id: int,
    payload: EvaluateReplyCreate,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return EvaluateService.reply_evaluation(
        db=db,
        evaluate_id=evaluate_id,
        admin_id=current_admin.id,
        admin_reply=payload.admin_reply,
    )

