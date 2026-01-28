from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from sqlalchemy.orm import Session
from typing import Dict, List, Optional
from pydantic import ValidationError

import cloudinary.uploader
from app.api.utils import extract_replace_images_map, extract_uploads, parse_int, parse_int_list, upload_images_to_cloudinary
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
        if isinstance(value, UploadFile):
            return None
        if value is None:
            return None
        value = str(value).strip()
        return value or None

    description = _get_str("description") or _get_str("des")
    return {
        "name": _get_str("name"),
        "description": description,
        "unit": _get_str("unit"),
        "category_id": parse_int(_get_str("category_id")),
    }


async def _update_product_from_request(product_id: int, request: Request, db: Session):
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()
        payload = _parse_form_product_fields(form)
        existing = ProductService.get_product_byID(db, product_id)

        if not payload.get("name"):
            payload["name"] = existing.name
        if payload.get("description") is None:
            payload["description"] = existing.description
        if not payload.get("unit"):
            payload["unit"] = existing.unit
        if payload.get("category_id") is None:
            payload["category_id"] = existing.category_id

        try:
            product_in = ProductCreate(**payload)
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=exc.errors())

        ProductService.update_product(db, product_id, product_in)

        replace_images = extract_replace_images_map(form)
        remove_ids = parse_int_list(form.getlist("remove_image_ids[]"))
        if replace_images:
            replace_ids = set(replace_images.keys())
            remove_ids = [image_id for image_id in remove_ids if image_id not in replace_ids]

        for image_id in remove_ids:
            ImageService.delete_image(db, image_id)

        for image_id, file in replace_images.items():
            ImageService.replace_image(db, image_id, file, product_id=product_id)

        new_files = extract_uploads(form.getlist("images[]"))
        color_ids = parse_int_list(form.getlist("image_color_ids[]"))
        uploaded = upload_images_to_cloudinary(new_files, color_ids)
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
    """
    L???y s???n ph???m thu???c v??? m???t danh m???c c??? th??? (c?? ph??n trang)
    """
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
    API tao san pham moi
    """
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()

        payload = _parse_form_product_fields(form)

        if not payload.get("name") or not payload.get("unit") or payload.get("category_id") is None:
            raise HTTPException(status_code=422, detail="Missing required fields")

        try:
            product_in = ProductCreate(**payload)
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=exc.errors())

        new_product = ProductService.create_product(db, product_in)

        files = extract_uploads(form.getlist("images[]"))
        color_ids = parse_int_list(form.getlist("image_color_ids[]"))
        uploaded = upload_images_to_cloudinary(files, color_ids)
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
    ImageService.deleteAll_image(db, product_id)
    return ProductService.delete_product(db,product_id)


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
