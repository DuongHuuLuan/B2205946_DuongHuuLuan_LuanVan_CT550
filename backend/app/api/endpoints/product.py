from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from sqlalchemy.orm import Session
from typing import Dict, List, Optional
from pydantic import ValidationError

import cloudinary.uploader
from app.api.utils import (
    build_absolute_static_url,
    delete_model_3d_from_cloudinary,
    delete_local_model_3d_by_url,
    extract_replace_images_map,
    extract_view_image_key_map,
    extract_uploads,
    is_upload_file,
    normalize_view_image_key,
    parse_int,
    parse_int_list,
    upload_images_to_cloudinary,
    upload_model_3d_to_static,
)
from app.db.session import get_db
from app.schemas.product import ProductCreate, ProductOut, ProductPaginationOut
from app.services.product_service import ProductService
from app.services.image_service import ImageService
from app.models.user import User
from app.api.deps import require_admin, require_user
router  = APIRouter(prefix="/products", tags=["Products"])

def _parse_form_product_fields(form):
    def _get_str(key):
        value = form.get(key)
        if is_upload_file(value):
            return None
        if value is None:
            return None
        value = str(value).strip()
        return value or None

    description = _get_str("description") or _get_str("des")
    return {
        "name": _get_str("name"),
        "description": description,
        "model_3d_url": _get_str("model_3d_url") or _get_str("model3dUrl"),
        "unit": _get_str("unit"),
        "category_id": parse_int(_get_str("category_id")),
    }


async def _update_product_from_request(product_id: int, request: Request, db: Session):
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()
        payload = _parse_form_product_fields(form)
        existing = ProductService.get_product_byID(db, product_id)
        has_model_3d_url = "model_3d_url" in form or "model3dUrl" in form
        model_3d_file = form.get("model_3d_file")
        uploaded_model_relative_url = None
        old_model_public_id = existing.model_3d_public_id
        old_model_url = existing.model_3d_url

        if is_upload_file(model_3d_file) and (model_3d_file.filename or "").strip():
            try:
                uploaded_model_relative_url = upload_model_3d_to_static(model_3d_file)
            except ValueError as exc:
                raise HTTPException(status_code=422, detail=str(exc))
            payload["model_3d_url"] = build_absolute_static_url(
                str(request.base_url),
                uploaded_model_relative_url,
            )
            has_model_3d_url = True

        if not payload.get("name"):
            payload["name"] = existing.name
        if payload.get("description") is None:
            payload["description"] = existing.description
        if not has_model_3d_url:
            payload["model_3d_url"] = existing.model_3d_url
        if not payload.get("unit"):
            payload["unit"] = existing.unit
        if payload.get("category_id") is None:
            payload["category_id"] = existing.category_id

        try:
            product_in = ProductCreate(**payload)
        except ValidationError as exc:
            if uploaded_model_relative_url:
                delete_local_model_3d_by_url(uploaded_model_relative_url)
            raise HTTPException(status_code=422, detail=exc.errors())

        try:
            updated_product = ProductService.update_product(db, product_id, product_in)
            if has_model_3d_url:
                updated_product.model_3d_public_id = None
                db.commit()
                db.refresh(updated_product)
        except Exception:
            db.rollback()
            if uploaded_model_relative_url:
                delete_local_model_3d_by_url(uploaded_model_relative_url)
            raise

        if old_model_url and old_model_url != getattr(updated_product, "model_3d_url", None):
            delete_local_model_3d_by_url(old_model_url)
        if old_model_public_id and old_model_public_id != getattr(updated_product, "model_3d_public_id", None):
            try:
                delete_model_3d_from_cloudinary(old_model_public_id)
            except Exception:
                pass

        replace_images = extract_replace_images_map(form)
        view_image_key_updates = extract_view_image_key_map(form)
        remove_ids = parse_int_list(form.getlist("remove_image_ids[]"))
        if replace_images:
            replace_ids = set(replace_images.keys())
            remove_ids = [image_id for image_id in remove_ids if image_id not in replace_ids]

        for image_id in remove_ids:
            ImageService.delete_image(db, image_id)

        for image_id, file in replace_images.items():
            ImageService.replace_image(db, image_id, file, product_id=product_id)

        for image_id, view_image_key in view_image_key_updates.items():
            if image_id in remove_ids:
                continue
            ImageService.update_view_image_key(
                db,
                image_id,
                view_image_key,
                product_id=product_id,
            )

        new_files = extract_uploads(form.getlist("images[]"))
        color_ids = [parse_int(value) for value in form.getlist("image_color_ids[]")]
        view_image_keys = [
            normalize_view_image_key(value)
            for value in form.getlist("new_view_image_keys[]")
        ]
        uploaded = upload_images_to_cloudinary(
            new_files,
            color_ids,
            view_image_keys,
        )
        if uploaded:
            ImageService.add_images(db, product_id=product_id, images=uploaded)

        return ProductService.get_product_byID(db, product_id)

    data = await request.json()
    try:
        product_in = ProductCreate(**data)
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors())

    ProductService.update_product(db, product_id, product_in)

    if product_in.images is not None:
        ImageService.deleteAll_image(db, product_id)
        ImageService.add_images(
            db,
            product_id=product_id,
            images=[img.model_dump() for img in product_in.images],
        )

    return ProductService.get_product_byID(db, product_id)

@router.get("/", response_model=ProductPaginationOut)
def getAll_product(
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
):
    """
    API Lấy tất cả sản phẩm
    """
    return ProductService.get_products_paginated(
        db,
        page=page,
        per_page=per_page,
        keyword=q,
    )

@router.get("/category/{category_id}", response_model=ProductPaginationOut)
def get_product_category(
    category_id: int,
    page: int = 1,
    per_page: Optional[int] = None,
    q: str = None,
    db: Session = Depends(get_db),
):
    
    return ProductService.get_products_paginated(
        db,
        page=page,
        per_page=per_page,
        keyword=q,
        category_id=category_id,
    )
@router.post("/", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
async def create_product(
    request: Request,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """
    API tạo sản phẩm mới
    """
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()

        payload = _parse_form_product_fields(form)
        model_3d_file = form.get("model_3d_file")
        uploaded_model_relative_url = None

        if is_upload_file(model_3d_file) and (model_3d_file.filename or "").strip():
            try:
                uploaded_model_relative_url = upload_model_3d_to_static(model_3d_file)
            except ValueError as exc:
                raise HTTPException(status_code=422, detail=str(exc))
            payload["model_3d_url"] = build_absolute_static_url(
                str(request.base_url),
                uploaded_model_relative_url,
            )

        if not payload.get("name") or not payload.get("unit") or payload.get("category_id") is None:
            if uploaded_model_relative_url:
                delete_local_model_3d_by_url(uploaded_model_relative_url)
            raise HTTPException(status_code=422, detail="Missing required fields")

        try:
            product_in = ProductCreate(**payload)
        except ValidationError as exc:
            if uploaded_model_relative_url:
                delete_local_model_3d_by_url(uploaded_model_relative_url)
            raise HTTPException(status_code=422, detail=exc.errors())

        try:
            new_product = ProductService.create_product(db, product_in)
            if uploaded_model_relative_url:
                new_product.model_3d_public_id = None
                db.commit()
                db.refresh(new_product)
        except Exception:
            db.rollback()
            if uploaded_model_relative_url:
                delete_local_model_3d_by_url(uploaded_model_relative_url)
            raise

        files = extract_uploads(form.getlist("images[]"))
        color_ids = [parse_int(value) for value in form.getlist("image_color_ids[]")]
        view_image_keys = [
            normalize_view_image_key(value)
            for value in form.getlist("new_view_image_keys[]")
        ]
        uploaded = upload_images_to_cloudinary(files, color_ids, view_image_keys)
        if uploaded:
            ImageService.add_images(db, product_id=new_product.id, images=uploaded)

        return ProductService.get_product_byID(db, new_product.id)

    data = await request.json()
    try:
        product_in = ProductCreate(**data)
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors())

    new_product = ProductService.create_product(db, product_in)
    if product_in.images:
        ImageService.add_images(
            db,
            product_id=new_product.id,
            images=[img.model_dump() for img in product_in.images],
        )

    return ProductService.get_product_byID(db, new_product.id)


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """
    API lấy chi tiết một sản phẩm (Bao gồm cả category và Images)
    """
    return ProductService.get_product_byID(db,product_id)


@router.put("/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    """
    API Cập nhật sản phẩm
    """
    return await _update_product_from_request(product_id, request, db)


@router.post("/{product_id}", response_model=ProductOut)
async def update_product_post(
    product_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return await _update_product_from_request(product_id, request, db)

@router.delete("/{product_id}", status_code=status.HTTP_200_OK)
def delete_product(product_id: int, db: Session = Depends(get_db), current_admin: User = Depends(require_admin)):
    """
    API xóa 1 sản phẩm theo Id
    """
    product = ProductService.ensure_product_can_delete(db, product_id)
    ImageService.deleteAll_image(db, product_id)
    result = ProductService.delete_product(db, product_id, skip_validate=True)
    delete_local_model_3d_by_url(getattr(product, "model_3d_url", None))
    if getattr(product, "model_3d_public_id", None):
        try:
            delete_model_3d_from_cloudinary(product.model_3d_public_id)
        except Exception:
            pass
    return result


@router.post("/{product_id}/images")
def upload_product_images(
    product_id: int,
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin)
):
    if not files:
        raise HTTPException(status_code=400, detail="Không có file nào")

    uploaded = []
    for f in files:
        r = cloudinary.uploader.upload(f.file, folder="helmet_shop/products")
        uploaded.append({"url": r["secure_url"], "public_id": r["public_id"]})

    # lưu DB
    db_images = ImageService.add_images(db, product_id, uploaded)

    return {
        "count": len(db_images),
        "items": [
            {"id": img.id, "url": img.url, "public_id": img.public_id}
            for img in db_images
        ],
    }

