from typing import List, Optional

import cloudinary.uploader
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from fastapi.params import Query
from sqlalchemy.orm import Session

from app.core.config import settings
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


def _upload_evaluate_images_to_cloudinary(files: List[UploadFile]) -> List[dict]:
    uploaded_images: List[dict] = []
    uploaded_public_ids: List[str] = []
    try:
        for file in files:
            result = cloudinary.uploader.upload(
                file.file,
                folder=settings.EVALUATE_IMAGE_CLOUDINARY_FOLDER,
                resource_type="image",
            )
            image_url = result.get("secure_url")
            public_id = result.get("public_id")
            if not image_url:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Cloudinary khÃ´ng tráº£ vá» URL áº£nh há»£p lá»‡",
                )
            uploaded_images.append({"url": image_url, "public_id": public_id})
            if public_id:
                uploaded_public_ids.append(public_id)
    except HTTPException:
        for public_id in uploaded_public_ids:
            try:
                cloudinary.uploader.destroy(public_id)
            except Exception:
                pass
        raise
    except Exception as exc:
        for public_id in uploaded_public_ids:
            try:
                cloudinary.uploader.destroy(public_id)
            except Exception:
                pass
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"KhÃ´ng thá»ƒ táº£i áº£nh Ä‘Ã¡nh giÃ¡ lÃªn Cloudinary: {exc}",
        ) from exc

    return uploaded_images

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
    uploaded_files = images or []

    if len(uploaded_files) > MAX_EVALUATE_IMAGES:
        raise HTTPException(status_code=400, detail=f"Chỉ được tải tối đa {MAX_EVALUATE_IMAGES} ảnh")

    for image in uploaded_files:
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Tất cả file tải lên phải là ảnh")
    uploaded_images = _upload_evaluate_images_to_cloudinary(uploaded_files)

    return EvaluateService.create_evaluation_with_uploaded_images(
        db=db,
        user_id=current_user.id,
        order_id=order_id,
        rate=rate,
        content=content,
        uploaded_images=uploaded_images,
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

