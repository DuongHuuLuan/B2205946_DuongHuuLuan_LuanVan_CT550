import secrets
from typing import Iterable, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, selectinload

from app.core.config import settings
from app.models import Design, DesignLayer, DesignShare, Product, ProductDetail
from app.schemas import CartDetailCreate
from app.schemas.design import DesignCreate, DesignLayerIn, DesignOrderIn, DesignUpdate
from app.services.base import BaseService
from app.services.cart_service import CartService
from app.services.sticker_service import StickerService


class DesignService(BaseService):
    _ALLOWED_VIEW_IMAGE_KEYS = {
        "front",
        "front_right",
        "right",
        "back",
        "left",
        "front_left",
    }

    @staticmethod
    def _query_with_relations(db: Session):
        return db.query(Design).options(
            selectinload(Design.layers),
            selectinload(Design.shares),
        )

    @staticmethod
    def _normalize_view_image_key(value: Optional[str]) -> Optional[str]:
        normalized = (value or "").strip().lower().replace(" ", "_")
        return normalized if normalized in DesignService._ALLOWED_VIEW_IMAGE_KEYS else None

    @staticmethod
    def _get_design_or_404(db: Session, design_id: int) -> Design:
        design = (
            DesignService._query_with_relations(db)
            .filter(Design.id == design_id)
            .first()
        )
        if not design:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Không tìm thấy thiết kế",
            )
        return design

    @staticmethod
    def _get_owned_design(db: Session, design_id: int, user_id: int) -> Design:
        design = DesignService._get_design_or_404(db, design_id)
        DesignService.assert_owner(user_id, design.user_id, "Bạn không có quyền truy cập thiết kế này")
        return design

    @staticmethod
    def _ensure_product_exists(db: Session, product_id: int) -> Product:
        return DesignService.get_or_404(db, Product, product_id, "Không tìm thấy sản phẩm")

    @staticmethod
    def _normalize_layers(layers: Iterable[DesignLayerIn]) -> list[tuple[int, DesignLayerIn]]:
        indexed_layers = list(enumerate(layers))
        indexed_layers.sort(key=lambda item: (item[1].z_index, item[0]))
        return indexed_layers

    @staticmethod
    def _replace_layers(db: Session, design: Design, layers: list[DesignLayerIn], user_id: int) -> None:
        sticker_map = StickerService.get_accessible_sticker_map(
            db,
            [layer.sticker_id for layer in layers],
            user_id,
        )

        for existing_layer in list(design.layers):
            db.delete(existing_layer)
        db.flush()

        for normalized_z_index, (_, layer_in) in enumerate(DesignService._normalize_layers(layers)):
            sticker = sticker_map[layer_in.sticker_id]
            crop = layer_in.crop
            db.add(
                DesignLayer(
                    design_id=design.id,
                    sticker_id=layer_in.sticker_id,
                    image_url=layer_in.image_url or sticker.image_url,
                    x=layer_in.x,
                    y=layer_in.y,
                    scale=layer_in.scale,
                    rotation=layer_in.rotation,
                    z_index=normalized_z_index,
                    view_image_key=DesignService._normalize_view_image_key(
                        layer_in.view_image_key
                    ),
                    tint_color_value=layer_in.tint_color_value,
                    crop_left=crop.left,
                    crop_top=crop.top,
                    crop_right=crop.right,
                    crop_bottom=crop.bottom,
                )
            )

    @staticmethod
    def create_design(db: Session, user_id: int, design_in: DesignCreate) -> Design:
        DesignService._ensure_product_exists(db, design_in.product_id)

        design = Design(
            user_id=user_id,
            product_id=design_in.product_id,
            name=design_in.name,
            base_image_url=design_in.base_image_url,
            is_shared=False,
        )
        db.add(design)
        db.flush()

        DesignService._replace_layers(db, design, design_in.stickers, user_id)
        db.commit()

        return DesignService._get_design_or_404(db, design.id)

    @staticmethod
    def update_design(db: Session, design_id: int, user_id: int, design_in: DesignUpdate) -> Design:
        if design_in.id != design_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ID trong path không khớp với ID trong body",
            )

        DesignService._ensure_product_exists(db, design_in.product_id)
        design = DesignService._get_owned_design(db, design_id, user_id)

        design.product_id = design_in.product_id
        design.name = design_in.name
        design.base_image_url = design_in.base_image_url

        DesignService._replace_layers(db, design, design_in.stickers, user_id)
        db.commit()

        return DesignService._get_design_or_404(db, design.id)

    @staticmethod
    def get_design_detail(db: Session, design_id: int, user_id: int) -> Design:
        return DesignService._get_owned_design(db, design_id, user_id)

    @staticmethod
    def _build_share_url(token: str) -> str:
        base_url = settings.APP_RETURN_URL.rstrip("/")
        if not base_url:
            return f"/designs/{token}"
        return f"{base_url}/designs/{token}"

    @staticmethod
    def create_share_link(db: Session, design_id: int, user_id: int) -> dict:
        design = DesignService._get_owned_design(db, design_id, user_id)

        existing_share = next(iter(design.shares), None)
        if existing_share:
            if not design.is_shared:
                design.is_shared = True
                db.commit()
            return {"share_url": existing_share.public_url}

        token = secrets.token_urlsafe(24)
        share_url = DesignService._build_share_url(token)

        share = DesignShare(
            design_id=design.id,
            share_token=token,
            public_url=share_url,
        )
        design.is_shared = True

        db.add(share)
        db.commit()

        return {"share_url": share_url}

    @staticmethod
    def order_design(db: Session, design_id: int, user_id: int, order_in: DesignOrderIn) -> dict:
        design = DesignService._get_owned_design(db, design_id, user_id)
        product_detail = DesignService.get_or_404(
            db,
            ProductDetail,
            order_in.product_detail_id,
            "Không tìm thấy biến thể sản phẩm",
        )

        if product_detail.product_id != design.product_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Biến thế sản phẩm không thuộc mẫu nón của thiết kế này",
            )

        cart = CartService.add_to_cart(
            db,
            user_id,
            CartDetailCreate(
                product_detail_id=order_in.product_detail_id,
                design_id=design.id,
                quantity=order_in.quantity,
            ),
        )
        cart_detail = next(
            (
                item
                for item in cart.cart_details
                if item.product_detail_id == order_in.product_detail_id
                and item.design_id == design.id
            ),
            None,
        )
        if cart_detail is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Không thể đưa thiết kế nào giỏ hàng",
            )

        return {
            "message": "Đã đưa thiết kế vào giỏ hàng",
            "cart_id": cart.id,
            "cart_detail_id": cart_detail.id,
            "design_id": design.id,
        }
