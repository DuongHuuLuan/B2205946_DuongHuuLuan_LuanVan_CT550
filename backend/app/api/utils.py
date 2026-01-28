
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import UploadFile
import cloudinary.uploader
from app.models.order import OrderStatus
from app.models.receipt import ReceiptStatus

#conver sang số nguyên
def parse_int(value) -> Optional[int]:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def parse_int_list(values) -> List[int]:
    result = []
    for value in values or []:
        parsed = parse_int(value)
        if parsed is not None:
            result.append(parsed)
    return result

def extract_uploads(values) -> List[UploadFile]:
    return [v for v in (values or []) if hasattr(v, "file")]

def extract_replace_images_map(form) -> Dict[int, UploadFile]:
    replace_map = {}
    for key, value in form.items():
        if not isinstance(value, UploadFile):
            continue
        if not key.startswith("replace_images[") or not key.endswith("]"):
            continue
        image_id = parse_int(key[len("replace_images[") : -1])
        if image_id is not None:
            replace_map[image_id] = value
    return replace_map

def upload_images_to_cloudinary(files: List[UploadFile], color_ids: List[int] = None):
    uploaded = []
    color_ids = color_ids or []
    for idx, f in enumerate(files):
        result = cloudinary.uploader.upload(
            f.file,
            folder="helmet_shop/products",
        )
        color_id = color_ids[idx] if idx < len(color_ids) else None
        uploaded.append({
            "url": result["secure_url"],
            "public_id": result["public_id"],
            "color_id": color_id,
        })
    return uploaded

def format_dashboard_meta(timestamp: Optional[datetime]) -> str:
    if not timestamp:
        return "--"
    return timestamp.strftime("%H:%M %d/%m")

def  get_status_tone(status: str) -> str:
    if status in [OrderStatus.CANCELLED, ReceiptStatus.CANCELLED]:
        return "alert"
    if status in [OrderStatus.PENDING, ReceiptStatus.PENDING]:
        return "warn"
    return "good"

def get_status_tag(status: str) -> str:
    status_map = {
        OrderStatus.PENDING: "Chờ xử lý",
        ReceiptStatus.PENDING: "Chờ xử lý",
        OrderStatus.CANCELLED: "Đã hủy",
        ReceiptStatus.CANCELLED: "Đã hủy",
        OrderStatus.SHIPPING: "Đang giao",
    }
    return status_map.get(status, "Hoàn tất")