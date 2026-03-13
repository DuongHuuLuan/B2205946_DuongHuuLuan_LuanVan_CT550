from fastapi import APIRouter, UploadFile, File, Depends, Form
from app.api.deps import require_admin
from app.models.user import User
import cloudinary.uploader

router = APIRouter(prefix="/images", tags=["Images"])

@router.post("/upload")
def upload_image(
    file: UploadFile = File(...),
    folder: str = Form(default="helmet_shop/products"),
    current_admin: User = Depends(require_admin)
):
    """
    Upload ảnh lên Cloudinary (test trên Swagger)
    """
    result = cloudinary.uploader.upload(
        file.file,
        folder=folder or "helmet_shop/products"
    )

    return {
        "url": result["secure_url"],
        "public_id": result["public_id"]
    }
