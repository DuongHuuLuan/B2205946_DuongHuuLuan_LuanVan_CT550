import math
from typing import Any, Optional

from app.models.design import Design
from app.models.design_layer import DesignLayer


class ProductionSnapshotService:
    DEFAULT_CANVAS_WIDTH_PX = 1080.0
    DEFAULT_CANVAS_HEIGHT_PX = 1000.0
    DEFAULT_PRINTABLE_WIDTH_MM = 240.0
    DEFAULT_PRINTABLE_HEIGHT_MM = round(
        DEFAULT_PRINTABLE_WIDTH_MM
        * (DEFAULT_CANVAS_HEIGHT_PX / DEFAULT_CANVAS_WIDTH_PX),
        2,
    )
    BASE_LAYER_RATIO = 0.24
    MIN_LAYER_PX = 34.0
    MAX_LAYER_RATIO = 0.52
    _VIEW_IMAGE_ORDER = {
        "front": 0,
        "front_right": 1,
        "right": 2,
        "back": 3,
        "left": 4,
        "front_left": 5,
    }

    @staticmethod
    def _normalize_view_image_key(value: Any) -> Optional[str]:
        key = str(value or "").strip().lower()
        return key or None

    @staticmethod
    def _view_order(view_image_key: Any) -> int:
        key = ProductionSnapshotService._normalize_view_image_key(view_image_key)
        if key is None:
            return len(ProductionSnapshotService._VIEW_IMAGE_ORDER) + 1
        return ProductionSnapshotService._VIEW_IMAGE_ORDER.get(
            key,
            len(ProductionSnapshotService._VIEW_IMAGE_ORDER),
        )

    @staticmethod
    def _view_label(view_image_key: Any) -> Optional[str]:
        mapping = {
            "front": "Mặt trước",
            "front_right": "Chéo phải",
            "right": "Bên phải",
            "back": "Mặt sau",
            "left": "Bên trái",
            "front_left": "Chéo trái",
        }
        key = ProductionSnapshotService._normalize_view_image_key(view_image_key)
        if key is None:
            return None
        return mapping.get(key)

    @staticmethod
    def _pick_primary_image(images: list[Any]) -> Optional[Any]:
        if not images:
            return None

        front = next(
            (
                image
                for image in images
                if ProductionSnapshotService._normalize_view_image_key(
                    getattr(image, "view_image_key", None)
                )
                == "front"
            ),
            None,
        )
        if front:
            return front

        generic = next(
            (
                image
                for image in images
                if ProductionSnapshotService._normalize_view_image_key(
                    getattr(image, "view_image_key", None)
                )
                is None
            ),
            None,
        )
        return generic or images[0]

    @staticmethod
    def _dedupe_view_images(raw_items: list[dict[str, Any]]) -> list[dict[str, Any]]:
        seen: set[tuple[Optional[str], str]] = set()
        items: list[dict[str, Any]] = []

        for raw in raw_items:
            view_image_key = ProductionSnapshotService._normalize_view_image_key(
                raw.get("view_image_key")
            )
            base_image_url = str(
                raw.get("base_image_url") or raw.get("url") or ""
            ).strip()
            if not base_image_url:
                continue

            key = (view_image_key, base_image_url)
            if key in seen:
                continue
            seen.add(key)
            items.append(
                {
                    "view_image_key": view_image_key,
                    "base_image_url": base_image_url,
                    "preview_image_url": str(
                        raw.get("preview_image_url") or base_image_url
                    ).strip()
                    or base_image_url,
                }
            )

        items.sort(
            key=lambda item: (
                ProductionSnapshotService._view_order(item.get("view_image_key")),
                str(item.get("view_image_key") or ""),
                str(item.get("base_image_url") or ""),
            )
        )
        return items

    @staticmethod
    def _resolve_view_images_from_product(
        product_images: Optional[list[Any]],
        color_id: Optional[int] = None,
    ) -> list[dict[str, Any]]:
        images = list(product_images or [])
        if not images:
            return []

        by_color = [
            image for image in images if getattr(image, "color_id", None) == color_id
        ]
        common_images = [
            image for image in images if getattr(image, "color_id", None) is None
        ]

        for bucket in (by_color, common_images):
            keyed = [
                image
                for image in bucket
                if ProductionSnapshotService._normalize_view_image_key(
                    getattr(image, "view_image_key", None)
                )
                is not None
            ]
            if keyed:
                return ProductionSnapshotService._dedupe_view_images(
                    [
                        {
                            "view_image_key": getattr(image, "view_image_key", None),
                            "base_image_url": getattr(image, "url", None),
                            "preview_image_url": getattr(image, "url", None),
                        }
                        for image in keyed
                    ]
                )

        primary = ProductionSnapshotService._pick_primary_image(by_color)
        if primary is None:
            primary = ProductionSnapshotService._pick_primary_image(common_images)
        if primary is None:
            primary = ProductionSnapshotService._pick_primary_image(images)
        if primary is None:
            return []

        return ProductionSnapshotService._dedupe_view_images(
            [
                {
                    "view_image_key": getattr(primary, "view_image_key", None),
                    "base_image_url": getattr(primary, "url", None),
                    "preview_image_url": getattr(primary, "url", None),
                }
            ]
        )

    @staticmethod
    def _resolve_snapshot_view_images(
        snapshot: dict[str, Any],
        product_images: Optional[list[Any]] = None,
        color_id: Optional[int] = None,
    ) -> list[dict[str, Any]]:
        raw = snapshot.get("view_images")
        if isinstance(raw, list) and raw:
            items = ProductionSnapshotService._dedupe_view_images(
                [item for item in raw if isinstance(item, dict)]
            )
            if items:
                return items

        items = ProductionSnapshotService._resolve_view_images_from_product(
            product_images,
            color_id,
        )
        if items:
            return items

        fallback_url = str(
            snapshot.get("base_image_url") or snapshot.get("preview_image_url") or ""
        ).strip()
        if not fallback_url:
            return []

        return [
            {
                "view_image_key": None,
                "base_image_url": fallback_url,
                "preview_image_url": fallback_url,
            }
        ]

    @staticmethod
    def _build_view_payloads(
        snapshot: dict[str, Any],
        layers: list[dict[str, Any]],
        view_images: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        grouped: dict[Optional[str], list[dict[str, Any]]] = {}
        for layer in layers:
            key = ProductionSnapshotService._normalize_view_image_key(
                layer.get("view_image_key")
            )
            grouped.setdefault(key, []).append(layer)

        views: list[dict[str, Any]] = []
        for view in view_images:
            key = ProductionSnapshotService._normalize_view_image_key(
                view.get("view_image_key")
            )
            view_layers = grouped.pop(key, [])
            base_image_url = str(view.get("base_image_url") or "").strip()
            preview_image_url = str(
                view.get("preview_image_url") or base_image_url
            ).strip() or base_image_url
            views.append(
                {
                    "view_image_key": key,
                    "label": ProductionSnapshotService._view_label(key)
                    or "Ảnh mặc định",
                    "base_image_url": base_image_url or None,
                    "preview_image_url": preview_image_url or None,
                    "layers": view_layers,
                }
            )

        fallback_base_image = str(
            snapshot.get("base_image_url") or snapshot.get("preview_image_url") or ""
        ).strip()
        for key, view_layers in grouped.items():
            views.append(
                {
                    "view_image_key": key,
                    "label": ProductionSnapshotService._view_label(key)
                    or "Ảnh mặc định",
                    "base_image_url": fallback_base_image or None,
                    "preview_image_url": fallback_base_image or None,
                    "layers": view_layers,
                }
            )

        if not views:
            views.append(
                {
                    "view_image_key": None,
                    "label": "Ảnh mặc định",
                    "base_image_url": fallback_base_image or None,
                    "preview_image_url": fallback_base_image or None,
                    "layers": layers,
                }
            )

        views.sort(
            key=lambda item: (
                ProductionSnapshotService._view_order(item.get("view_image_key")),
                str(item.get("view_image_key") or ""),
            )
        )
        return views

    @staticmethod
    def _serialize_layer(layer: DesignLayer) -> dict[str, Any]:
        return {
            "id": layer.id,
            "sticker_id": layer.sticker_id,
            "sticker_name": getattr(getattr(layer, "sticker", None), "name", None),
            "image_url": layer.image_url,
            "x": layer.x,
            "y": layer.y,
            "scale": layer.scale,
            "rotation": layer.rotation,
            "z_index": layer.z_index,
            "view_image_key": getattr(layer, "view_image_key", None),
            "tint_color_value": layer.tint_color_value,
            "crop": {
                "left": layer.crop_left,
                "top": layer.crop_top,
                "right": layer.crop_right,
                "bottom": layer.crop_bottom,
            },
        }

    @staticmethod
    def build_design_snapshot(
        design: Optional[Design],
        product_images: Optional[list[Any]] = None,
        color_id: Optional[int] = None,
    ) -> Optional[dict[str, Any]]:
        if not design:
            return None

        layers = sorted(
            list(getattr(design, "layers", []) or []),
            key=lambda item: item.z_index,
        )
        snapshot = {
            "design_id": design.id,
            "name": design.name,
            "base_image_url": design.base_image_url,
            "preview_image_url": design.preview_image_url,
            "is_shared": design.is_shared,
            "canvas_width_px": ProductionSnapshotService.DEFAULT_CANVAS_WIDTH_PX,
            "canvas_height_px": ProductionSnapshotService.DEFAULT_CANVAS_HEIGHT_PX,
            "printable_width_mm": ProductionSnapshotService.DEFAULT_PRINTABLE_WIDTH_MM,
            "printable_height_mm": ProductionSnapshotService.DEFAULT_PRINTABLE_HEIGHT_MM,
            "layers": [
                ProductionSnapshotService._serialize_layer(layer) for layer in layers
            ],
        }

        view_images = ProductionSnapshotService._resolve_view_images_from_product(
            product_images,
            color_id,
        )
        if view_images:
            snapshot["view_images"] = view_images
        return snapshot

    @staticmethod
    def _snapshot_or_fallback(order_detail: Any) -> dict[str, Any]:
        snapshot = getattr(order_detail, "design_snapshot_json", None)
        if isinstance(snapshot, dict) and snapshot:
            return snapshot

        product_detail = getattr(order_detail, "product_detail", None)
        product = getattr(product_detail, "product", None)
        return ProductionSnapshotService.build_design_snapshot(
            getattr(order_detail, "design", None),
            product_images=list(getattr(product, "product_images", []) or []),
            color_id=getattr(product_detail, "color_id", None),
        ) or {}

    @staticmethod
    def _normalize_crop(raw_crop: Any) -> dict[str, float]:
        crop = raw_crop if isinstance(raw_crop, dict) else {}
        left = float(crop.get("left", 0.0) or 0.0)
        top = float(crop.get("top", 0.0) or 0.0)
        right = float(crop.get("right", 1.0) or 1.0)
        bottom = float(crop.get("bottom", 1.0) or 1.0)

        left = max(0.0, min(left, 1.0))
        top = max(0.0, min(top, 1.0))
        right = max(left, min(right, 1.0))
        bottom = max(top, min(bottom, 1.0))

        return {
            "left": left,
            "top": top,
            "right": right,
            "bottom": bottom,
        }

    @staticmethod
    def _resolve_canvas_width(snapshot: dict[str, Any]) -> float:
        return float(
            snapshot.get("canvas_width_px")
            or ProductionSnapshotService.DEFAULT_CANVAS_WIDTH_PX
        )

    @staticmethod
    def _resolve_canvas_height(snapshot: dict[str, Any]) -> float:
        return float(
            snapshot.get("canvas_height_px")
            or ProductionSnapshotService.DEFAULT_CANVAS_HEIGHT_PX
        )

    @staticmethod
    def _resolve_printable_width_mm(snapshot: dict[str, Any]) -> float:
        return float(
            snapshot.get("printable_width_mm")
            or ProductionSnapshotService.DEFAULT_PRINTABLE_WIDTH_MM
        )

    @staticmethod
    def _resolve_printable_height_mm(snapshot: dict[str, Any]) -> float:
        return float(
            snapshot.get("printable_height_mm")
            or ProductionSnapshotService.DEFAULT_PRINTABLE_HEIGHT_MM
        )

    @staticmethod
    def _layer_box_size_px(scale: float, canvas_width_px: float) -> float:
        visual_size = (
            canvas_width_px * ProductionSnapshotService.BASE_LAYER_RATIO * scale
        )
        return float(
            max(
                ProductionSnapshotService.MIN_LAYER_PX,
                min(
                    visual_size,
                    canvas_width_px * ProductionSnapshotService.MAX_LAYER_RATIO,
                ),
            )
        )

    @staticmethod
    def _layer_left_px(x: float, box_size_px: float, canvas_width_px: float) -> float:
        return float(
            max(
                0.0,
                min(
                    (x * canvas_width_px) - (box_size_px / 2),
                    canvas_width_px - box_size_px,
                ),
            )
        )

    @staticmethod
    def _layer_top_px(y: float, box_size_px: float, canvas_height_px: float) -> float:
        return float(
            max(
                0.0,
                min(
                    (y * canvas_height_px) - (box_size_px / 2),
                    canvas_height_px - box_size_px,
                ),
            )
        )

    @staticmethod
    def _position_label(x: float, y: float) -> str:
        if y <= 0.24:
            return "Phía trên"
        if x < 0.33:
            return "Bên trái"
        if x > 0.67:
            return "Bên phải"
        if y >= 0.72:
            return "Phía sau"
        return "Mặt trước"

    @staticmethod
    def build_layer_spec(
        raw_layer: dict[str, Any],
        snapshot: dict[str, Any],
    ) -> dict[str, Any]:
        canvas_width_px = ProductionSnapshotService._resolve_canvas_width(snapshot)
        canvas_height_px = ProductionSnapshotService._resolve_canvas_height(snapshot)
        printable_width_mm = ProductionSnapshotService._resolve_printable_width_mm(
            snapshot
        )
        printable_height_mm = ProductionSnapshotService._resolve_printable_height_mm(
            snapshot
        )

        x = float(raw_layer.get("x", 0.0) or 0.0)
        y = float(raw_layer.get("y", 0.0) or 0.0)
        scale = float(raw_layer.get("scale", 1.0) or 1.0)
        rotation = float(raw_layer.get("rotation", 0.0) or 0.0)
        z_index = int(raw_layer.get("z_index", 0) or 0)
        view_image_key = ProductionSnapshotService._normalize_view_image_key(
            raw_layer.get("view_image_key")
        )
        crop = ProductionSnapshotService._normalize_crop(raw_layer.get("crop"))

        box_size_px = ProductionSnapshotService._layer_box_size_px(scale, canvas_width_px)
        left_px = ProductionSnapshotService._layer_left_px(x, box_size_px, canvas_width_px)
        top_px = ProductionSnapshotService._layer_top_px(y, box_size_px, canvas_height_px)
        visible_width_px = box_size_px * (crop["right"] - crop["left"])
        visible_height_px = box_size_px * (crop["bottom"] - crop["top"])
        visible_offset_x_px = box_size_px * crop["left"]
        visible_offset_y_px = box_size_px * crop["top"]

        render_width_mm = (visible_width_px / canvas_width_px) * printable_width_mm
        render_height_mm = (
            visible_height_px / canvas_height_px
        ) * printable_height_mm
        box_size_mm = (box_size_px / canvas_width_px) * printable_width_mm

        return {
            "sticker_id": raw_layer.get("sticker_id"),
            "sticker_name": raw_layer.get("sticker_name"),
            "image_url": raw_layer.get("image_url"),
            "x": x,
            "y": y,
            "scale": scale,
            "rotation": rotation,
            "rotation_degrees": round(math.degrees(rotation), 2),
            "z_index": z_index,
            "view_image_key": view_image_key,
            "crop": crop,
            "render_width_mm": round(render_width_mm, 2),
            "render_height_mm": round(render_height_mm, 2),
            "box_size_mm": round(box_size_mm, 2),
            "position_label": ProductionSnapshotService._view_label(view_image_key)
            or ProductionSnapshotService._position_label(x, y),
            "box_size_px": round(box_size_px, 2),
            "left_px": round(left_px, 2),
            "top_px": round(top_px, 2),
            "visible_width_px": round(visible_width_px, 2),
            "visible_height_px": round(visible_height_px, 2),
            "visible_offset_x_px": round(visible_offset_x_px, 2),
            "visible_offset_y_px": round(visible_offset_y_px, 2),
            "canvas_width_px": round(canvas_width_px, 2),
            "canvas_height_px": round(canvas_height_px, 2),
            "printable_width_mm": round(printable_width_mm, 2),
            "printable_height_mm": round(printable_height_mm, 2),
        }

    @staticmethod
    def build_order_detail_payload(order_detail: Any) -> dict[str, Any]:
        snapshot = ProductionSnapshotService._snapshot_or_fallback(order_detail)
        raw_layers = sorted(
            list(snapshot.get("layers") or []),
            key=lambda item: int(item.get("z_index", 0) or 0),
        )
        layers = [
            ProductionSnapshotService.build_layer_spec(raw_layer, snapshot)
            for raw_layer in raw_layers
        ]

        product_detail = getattr(order_detail, "product_detail", None)
        product = getattr(product_detail, "product", None)
        view_images = ProductionSnapshotService._resolve_snapshot_view_images(
            snapshot,
            product_images=list(getattr(product, "product_images", []) or []),
            color_id=getattr(product_detail, "color_id", None),
        )
        views = ProductionSnapshotService._build_view_payloads(
            snapshot,
            layers,
            view_images,
        )

        return {
            "order_detail_id": getattr(order_detail, "id", 0),
            "product_detail_id": getattr(order_detail, "product_detail_id", 0),
            "product_name": getattr(product, "name", None),
            "quantity": getattr(order_detail, "quantity", 0),
            "base_image_url": snapshot.get("base_image_url"),
            "preview_image_url": snapshot.get("preview_image_url"),
            "design_snapshot_json": snapshot or None,
            "canvas_width_px": ProductionSnapshotService._resolve_canvas_width(
                snapshot
            ),
            "canvas_height_px": ProductionSnapshotService._resolve_canvas_height(
                snapshot
            ),
            "printable_width_mm": ProductionSnapshotService._resolve_printable_width_mm(
                snapshot
            ),
            "printable_height_mm": ProductionSnapshotService._resolve_printable_height_mm(
                snapshot
            ),
            "layers": layers,
            "views": views,
        }

    @staticmethod
    def build_order_production_payload(order: Any) -> dict[str, Any]:
        items = [
            ProductionSnapshotService.build_order_detail_payload(order_detail)
            for order_detail in getattr(order, "order_details", []) or []
        ]

        payment_status = getattr(order, "payment_status", None)
        refund_support_status = getattr(order, "refund_support_status", None)
        status = getattr(order, "status", None)

        return {
            "order_id": getattr(order, "id", 0),
            "status": getattr(status, "value", status),
            "payment_status": getattr(payment_status, "value", payment_status),
            "refund_support_status": getattr(
                refund_support_status,
                "value",
                refund_support_status,
            ),
            "rejection_reason": getattr(order, "rejection_reason", None),
            "items": items,
        }
