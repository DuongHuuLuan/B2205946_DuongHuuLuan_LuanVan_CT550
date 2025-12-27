import uuid
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.api.deps import require_user
import shutil
import os

from app.models.user import User
from app.schemas.evaluate import EvaluateCreate, EvaluateOut
from app.services.evaluate_service import EvaluateService

router = APIRouter(prefix="/evaluates", tags=["Evaluates"])

@router.post("/{order_id}", response_model=EvaluateOut)
async def post_evaluate(
    order_id: int,
    rate: int = Form(..., ge=1, le=5),
    content: str = Form(None),
    image: UploadFile = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user)
):
    image_url = None
    if image:
        if not image.content_type.startswith()("image/"):
            raise HTTPException(status_code=400, detail="File phải là định dạng ảnh")
        
        upload_dir = "static/evaluates"
        os.makedirs(upload_dir, exist_ok=True)

        #tạo tên file duy nhất để tránh trùng lặp
        file_extension = os.path.splitext(image.filename)[1]
        file_name = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(upload_dir, file_name)

        with open(file_path,"wb") as buffer:
            content_file = await image.read()
            buffer.write(content_file)

        image_url = f"/{file_path}" # đường dẫn để lưu vào DB
    
    return EvaluateService.create_evaluation(
        db = db,
        user_id= current_user.id,
        order_id=order_id,
        rate = rate,
        content = content,
        image_url = image_url
    )