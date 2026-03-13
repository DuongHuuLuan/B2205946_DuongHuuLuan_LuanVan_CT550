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
            "tint_color_value": layer.tint_color_value,
            "crop": {
                "left": layer.crop_left,
                "top": layer.crop_top,
                "right": layer.crop_right,
                "bottom": layer.crop_bottom,
            },
        }

    @staticmethod
    def build_design_snapshot(design: Optional[Design]) -> Optional[dict[str, Any]]:
        if not design:
            return None

        layers = sorted(
            list(getattr(design, "layers", []) or []),
            key=lambda item: item.z_index,
        )
        return {
            "design_id": design.id,
            "name": design.name,
            "base_image_url": design.base_image_url,
            "preview_image_url": design.preview_image_url,
            "is_shared": design.is_shared,
            "canvas_width_px": ProductionSnapshotService.DEFAULT_CANVAS_WIDTH_PX,
            "canvas_height_px": ProductionSnapshotService.DEFAULT_CANVAS_HEIGHT_PX,
            "printable_width_mm": ProductionSnapshotService.DEFAULT_PRINTABLE_WIDTH_MM,
            "printable_height_mm": ProductionSnapshotService.DEFAULT_PRINTABLE_HEIGHT_MM,
            "layers": [ProductionSnapshotService._serialize_layer(layer) for layer in layers],
        }

    @staticmethod
    def _snapshot_or_fallback(order_detail: Any) -> dict[str, Any]:
        snapshot = getattr(order_detail, "design_snapshot_json", None)
        if isinstance(snapshot, dict) and snapshot:
            return snapshot

        return ProductionSnapshotService.build_design_snapshot(
            getattr(order_detail, "design", None)
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
        visual_size = canvas_width_px * ProductionSnapshotService.BASE_LAYER_RATIO * scale
        return float(
            max(
                ProductionSnapshotService.MIN_LAYER_PX,
                min(visual_size, canvas_width_px * ProductionSnapshotService.MAX_LAYER_RATIO),
            )
        )

    @staticmethod
    def _layer_left_px(x: float, box_size_px: float, canvas_width_px: float) -> float:
        return float(
            max(
                0.0,
                min((x * canvas_width_px) - (box_size_px / 2), canvas_width_px - box_size_px),
            )
        )

    @staticmethod
    def _layer_top_px(y: float, box_size_px: float, canvas_height_px: float) -> float:
        return float(
            max(
                0.0,
                min((y * canvas_height_px) - (box_size_px / 2), canvas_height_px - box_size_px),
            )
        )

    @staticmethod
    def _position_label(x: float, y: float) -> str:
        if y <= 0.24:
            return "Phia tren"
        if x < 0.33:
            return "Ben trai"
        if x > 0.67:
            return "Ben phai"
        if y >= 0.72:
            return "Phia sau"
        return "Mat truoc"

    @staticmethod
    def build_layer_spec(
        raw_layer: dict[str, Any],
        snapshot: dict[str, Any],
    ) -> dict[str, Any]:
        canvas_width_px = ProductionSnapshotService._resolve_canvas_width(snapshot)
        canvas_height_px = ProductionSnapshotService._resolve_canvas_height(snapshot)
        printable_width_mm = ProductionSnapshotService._resolve_printable_width_mm(snapshot)
        printable_height_mm = ProductionSnapshotService._resolve_printable_height_mm(snapshot)

        x = float(raw_layer.get("x", 0.0) or 0.0)
        y = float(raw_layer.get("y", 0.0) or 0.0)
        scale = float(raw_layer.get("scale", 1.0) or 1.0)
        rotation = float(raw_layer.get("rotation", 0.0) or 0.0)
        z_index = int(raw_layer.get("z_index", 0) or 0)
        crop = ProductionSnapshotService._normalize_crop(raw_layer.get("crop"))

        box_size_px = ProductionSnapshotService._layer_box_size_px(scale, canvas_width_px)
        left_px = ProductionSnapshotService._layer_left_px(x, box_size_px, canvas_width_px)
        top_px = ProductionSnapshotService._layer_top_px(y, box_size_px, canvas_height_px)
        visible_width_px = box_size_px * (crop["right"] - crop["left"])
        visible_height_px = box_size_px * (crop["bottom"] - crop["top"])
        visible_offset_x_px = box_size_px * crop["left"]
        visible_offset_y_px = box_size_px * crop["top"]

        render_width_mm = (visible_width_px / canvas_width_px) * printable_width_mm
        render_height_mm = (visible_height_px / canvas_height_px) * printable_height_mm
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
            "crop": crop,
            "render_width_mm": round(render_width_mm, 2),
            "render_height_mm": round(render_height_mm, 2),
            "box_size_mm": round(box_size_mm, 2),
            "position_label": ProductionSnapshotService._position_label(x, y),
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

        return {
            "order_detail_id": getattr(order_detail, "id", 0),
            "product_detail_id": getattr(order_detail, "product_detail_id", 0),
            "product_name": getattr(product, "name", None),
            "quantity": getattr(order_detail, "quantity", 0),
            "base_image_url": snapshot.get("base_image_url"),
            "preview_image_url": snapshot.get("preview_image_url"),
            "design_snapshot_json": snapshot or None,
            "canvas_width_px": ProductionSnapshotService._resolve_canvas_width(snapshot),
            "canvas_height_px": ProductionSnapshotService._resolve_canvas_height(snapshot),
            "printable_width_mm": ProductionSnapshotService._resolve_printable_width_mm(snapshot),
            "printable_height_mm": ProductionSnapshotService._resolve_printable_height_mm(snapshot),
            "layers": layers,
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
