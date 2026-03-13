import base64
import html
from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Any, Optional
from urllib.parse import urlparse

import httpx
from fastapi import HTTPException
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas
from sqlalchemy.orm import Session, joinedload

from app.models import Design, DesignLayer, Order, OrderDetail, ProductDetail
from app.services.production_snapshot_service import ProductionSnapshotService


class ProductionExportService:
    PAGE_WIDTH_PT, PAGE_HEIGHT_PT = A4
    PAGE_WIDTH_MM = PAGE_WIDTH_PT / mm
    PAGE_HEIGHT_MM = PAGE_HEIGHT_PT / mm
    REPO_ROOT = Path(__file__).resolve().parents[3]

    @staticmethod
    def get_order_production(db: Session, order_id: int) -> dict[str, Any]:
        order = ProductionExportService._get_order(db, order_id)
        return ProductionSnapshotService.build_order_production_payload(order)

    @staticmethod
    def export_order(
        db: Session,
        order_id: int,
        export_format: str,
        dpi: int = 300,
    ) -> tuple[bytes, str, str]:
        payload = ProductionExportService.get_order_production(db, order_id)
        safe_format = (export_format or "").strip().lower()
        timestamp = datetime.now().strftime("%Y%m%d-%H%M")

        if safe_format == "pdf":
            file_bytes = ProductionExportService._render_pdf(payload, dpi=dpi)
            return (
                file_bytes,
                "application/pdf",
                f"order-{order_id}-production-{timestamp}.pdf",
            )

        if safe_format == "svg":
            file_bytes = ProductionExportService._render_svg(payload).encode("utf-8")
            return (
                file_bytes,
                "image/svg+xml",
                f"order-{order_id}-production-{timestamp}.svg",
            )

        raise HTTPException(status_code=400, detail="Unsupported export format")

    @staticmethod
    def _get_order(db: Session, order_id: int) -> Order:
        order = (
            db.query(Order)
            .options(
                joinedload(Order.order_details)
                .joinedload(OrderDetail.product_detail)
                .joinedload(ProductDetail.product),
                joinedload(Order.order_details)
                .joinedload(OrderDetail.design)
                .joinedload(Design.layers)
                .joinedload(DesignLayer.sticker),
            )
            .filter(Order.id == order_id)
            .first()
        )
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        return order

    @staticmethod
    def _load_image_asset(
        source: Optional[str],
        cache: dict[str, dict[str, Any]],
    ) -> Optional[dict[str, Any]]:
        if not source:
            return None

        cached = cache.get(source)
        if cached is not None:
            return cached

        raw_bytes = None
        mime_type = None

        try:
            if source.startswith("http://") or source.startswith("https://"):
                response = httpx.get(source, timeout=12.0, follow_redirects=True)
                response.raise_for_status()
                raw_bytes = response.content
                mime_type = response.headers.get("content-type")
            elif source.startswith("assets/"):
                asset_path = ProductionExportService.REPO_ROOT / "frontend" / "user" / source
                if asset_path.exists():
                    raw_bytes = asset_path.read_bytes()
                    mime_type = ProductionExportService._guess_mime_type(asset_path.suffix)
            else:
                file_path = Path(source)
                if file_path.exists():
                    raw_bytes = file_path.read_bytes()
                    mime_type = ProductionExportService._guess_mime_type(file_path.suffix)
        except Exception:
            raw_bytes = None
            mime_type = None

        if not raw_bytes:
            cache[source] = None
            return None

        try:
            reader = ImageReader(BytesIO(raw_bytes))
            width_px, height_px = reader.getSize()
        except Exception:
            cache[source] = None
            return None

        if not mime_type:
            parsed = urlparse(source)
            mime_type = ProductionExportService._guess_mime_type(Path(parsed.path).suffix)

        asset = {
            "bytes": raw_bytes,
            "mime_type": mime_type or "image/png",
            "reader": reader,
            "width_px": width_px,
            "height_px": height_px,
        }
        cache[source] = asset
        return asset

    @staticmethod
    def _guess_mime_type(extension: str) -> str:
        safe_extension = (extension or "").lower()
        if safe_extension in {".jpg", ".jpeg"}:
            return "image/jpeg"
        if safe_extension == ".webp":
            return "image/webp"
        if safe_extension == ".svg":
            return "image/svg+xml"
        return "image/png"

    @staticmethod
    def _draw_image_contain(
        pdf: canvas.Canvas,
        asset: Optional[dict[str, Any]],
        x_pt: float,
        y_pt: float,
        width_pt: float,
        height_pt: float,
    ) -> None:
        if not asset:
            pdf.saveState()
            pdf.setStrokeColor(colors.HexColor("#D1D5DB"))
            pdf.setFillColor(colors.HexColor("#F9FAFB"))
            pdf.rect(x_pt, y_pt, width_pt, height_pt, stroke=1, fill=1)
            pdf.setFillColor(colors.HexColor("#6B7280"))
            pdf.setFont("Helvetica", 9)
            pdf.drawString(x_pt + 8, y_pt + height_pt - 14, "Image unavailable")
            pdf.restoreState()
            return

        pdf.drawImage(
            asset["reader"],
            x_pt,
            y_pt,
            width=width_pt,
            height=height_pt,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )

    @staticmethod
    def _draw_layer_preview(
        pdf: canvas.Canvas,
        layer: dict[str, Any],
        preview_x_pt: float,
        preview_y_pt: float,
        scale_x: float,
        scale_y: float,
        image_cache: dict[str, dict[str, Any]],
    ) -> None:
        asset = ProductionExportService._load_image_asset(layer.get("image_url"), image_cache)
        if not asset:
            return

        box_width_pt = float(layer.get("box_size_px", 0.0) or 0.0) * scale_x
        box_height_pt = float(layer.get("box_size_px", 0.0) or 0.0) * scale_y
        left_pt = preview_x_pt + float(layer.get("left_px", 0.0) or 0.0) * scale_x
        top_px = float(layer.get("top_px", 0.0) or 0.0)
        canvas_height_px = float(layer.get("canvas_height_px", 0.0) or 0.0)
        box_size_px = float(layer.get("box_size_px", 0.0) or 0.0)
        bottom_pt = preview_y_pt + (canvas_height_px - top_px - box_size_px) * scale_y

        crop_offset_x_pt = float(layer.get("visible_offset_x_px", 0.0) or 0.0) * scale_x
        crop_offset_y_pt = float(layer.get("visible_offset_y_px", 0.0) or 0.0) * scale_y
        visible_width_pt = float(layer.get("visible_width_px", 0.0) or 0.0) * scale_x
        visible_height_pt = float(layer.get("visible_height_px", 0.0) or 0.0) * scale_y
        rotation_degrees = float(layer.get("rotation_degrees", 0.0) or 0.0)

        pdf.saveState()
        center_x = left_pt + (box_width_pt / 2)
        center_y = bottom_pt + (box_height_pt / 2)
        pdf.translate(center_x, center_y)
        pdf.rotate(rotation_degrees)

        clip_x = (-box_width_pt / 2) + crop_offset_x_pt
        clip_y = (box_height_pt / 2) - crop_offset_y_pt - visible_height_pt
        clip_path = pdf.beginPath()
        clip_path.rect(clip_x, clip_y, visible_width_pt, visible_height_pt)
        pdf.clipPath(clip_path, stroke=0, fill=0)

        pdf.drawImage(
            asset["reader"],
            -box_width_pt / 2,
            -box_height_pt / 2,
            width=box_width_pt,
            height=box_height_pt,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )
        pdf.restoreState()

    @staticmethod
    def _render_pdf(payload: dict[str, Any], dpi: int = 300) -> bytes:
        buffer = BytesIO()
        pdf = canvas.Canvas(buffer, pagesize=A4)
        image_cache: dict[str, dict[str, Any]] = {}

        items = payload.get("items") or []
        for item_index, item in enumerate(items):
            ProductionExportService._draw_pdf_preview_page(
                pdf=pdf,
                payload=payload,
                item=item,
                item_index=item_index,
                image_cache=image_cache,
                dpi=dpi,
            )
            pdf.showPage()
            ProductionExportService._draw_pdf_sticker_sheet(
                pdf=pdf,
                payload=payload,
                item=item,
                image_cache=image_cache,
                dpi=dpi,
            )
            if item_index < len(items) - 1:
                pdf.showPage()

        pdf.save()
        return buffer.getvalue()

    @staticmethod
    def _draw_pdf_preview_page(
        pdf: canvas.Canvas,
        payload: dict[str, Any],
        item: dict[str, Any],
        item_index: int,
        image_cache: dict[str, dict[str, Any]],
        dpi: int,
    ) -> None:
        margin_x = 14 * mm
        top_y = ProductionExportService.PAGE_HEIGHT_PT - (18 * mm)

        pdf.setTitle(f"Order {payload.get('order_id')} Production")
        pdf.setFont("Helvetica-Bold", 16)
        pdf.drawString(margin_x, top_y, f"Order #{payload.get('order_id')} - Production View")

        pdf.setFont("Helvetica", 10)
        pdf.setFillColor(colors.HexColor("#374151"))
        meta_lines = [
            f"Item {item_index + 1}: {item.get('product_name') or 'Helmet design'}",
            f"Order status: {payload.get('status')}",
            f"Payment: {payload.get('payment_status')}",
            f"Refund support: {payload.get('refund_support_status')}",
            f"Quantity: {item.get('quantity')}",
            f"Target export DPI: {dpi}",
        ]
        if payload.get("rejection_reason"):
            meta_lines.append(f"Rejection reason: {payload.get('rejection_reason')}")

        current_y = top_y - (8 * mm)
        for line in meta_lines:
            pdf.drawString(margin_x, current_y, line)
            current_y -= 5 * mm

        preview_width_pt = 120 * mm
        preview_height_pt = 112 * mm
        preview_x_pt = margin_x
        preview_y_pt = current_y - preview_height_pt - (4 * mm)

        pdf.setStrokeColor(colors.HexColor("#D1D5DB"))
        pdf.setFillColor(colors.HexColor("#FFFFFF"))
        pdf.rect(preview_x_pt, preview_y_pt, preview_width_pt, preview_height_pt, stroke=1, fill=1)

        base_asset = ProductionExportService._load_image_asset(
            item.get("base_image_url"),
            image_cache,
        )
        ProductionExportService._draw_image_contain(
            pdf,
            base_asset,
            preview_x_pt,
            preview_y_pt,
            preview_width_pt,
            preview_height_pt,
        )

        scale_x = preview_width_pt / float(item.get("canvas_width_px", 1.0) or 1.0)
        scale_y = preview_height_pt / float(item.get("canvas_height_px", 1.0) or 1.0)
        for layer in item.get("layers") or []:
            ProductionExportService._draw_layer_preview(
                pdf=pdf,
                layer=layer,
                preview_x_pt=preview_x_pt,
                preview_y_pt=preview_y_pt,
                scale_x=scale_x,
                scale_y=scale_y,
                image_cache=image_cache,
            )

        info_x = preview_x_pt + preview_width_pt + (10 * mm)
        info_y = preview_y_pt + preview_height_pt
        pdf.setFillColor(colors.HexColor("#111827"))
        pdf.setFont("Helvetica-Bold", 11)
        pdf.drawString(info_x, info_y, "Layer specs")
        info_y -= 6 * mm

        pdf.setFont("Helvetica", 9)
        for layer in item.get("layers") or []:
            lines = [
                f"- {layer.get('sticker_name') or 'Sticker'}",
                f"  Size: {layer.get('render_width_mm')} x {layer.get('render_height_mm')} mm",
                f"  Position: {layer.get('position_label')} | x={layer.get('x'):.3f}, y={layer.get('y'):.3f}",
                f"  Rotation: {layer.get('rotation_degrees')} deg | z={layer.get('z_index')}",
            ]
            for line in lines:
                pdf.drawString(info_x, info_y, line)
                info_y -= 4.5 * mm
            info_y -= 1.5 * mm
            if info_y <= 18 * mm:
                break

        pdf.setFont("Helvetica-Oblique", 8)
        pdf.setFillColor(colors.HexColor("#6B7280"))
        pdf.drawString(
            margin_x,
            12 * mm,
            "Preview uses the same normalized x/y/scale/rotation snapshot captured at checkout.",
        )

    @staticmethod
    def _draw_pdf_sticker_sheet(
        pdf: canvas.Canvas,
        payload: dict[str, Any],
        item: dict[str, Any],
        image_cache: dict[str, dict[str, Any]],
        dpi: int,
    ) -> None:
        margin_x = 14 * mm
        margin_top = ProductionExportService.PAGE_HEIGHT_PT - (16 * mm)
        current_y = margin_top

        def start_page_header() -> float:
            pdf.setFont("Helvetica-Bold", 15)
            pdf.setFillColor(colors.HexColor("#111827"))
            pdf.drawString(margin_x, ProductionExportService.PAGE_HEIGHT_PT - (18 * mm), "Sticker Print Sheet")
            pdf.setFont("Helvetica", 10)
            pdf.setFillColor(colors.HexColor("#374151"))
            pdf.drawString(
                margin_x,
                ProductionExportService.PAGE_HEIGHT_PT - (24 * mm),
                f"Order #{payload.get('order_id')} | Item: {item.get('product_name') or 'Helmet design'} | DPI target: {dpi}",
            )
            return ProductionExportService.PAGE_HEIGHT_PT - (32 * mm)

        current_y = start_page_header()
        for copy_index in range(int(item.get("quantity", 0) or 0)):
            pdf.setFont("Helvetica-Bold", 10)
            pdf.setFillColor(colors.HexColor("#111827"))
            pdf.drawString(margin_x, current_y, f"Copy set {copy_index + 1}/{item.get('quantity')}")
            current_y -= 6 * mm

            for layer in item.get("layers") or []:
                draw_width_pt = float(layer.get("render_width_mm", 0.0) or 0.0) * mm
                draw_height_pt = float(layer.get("render_height_mm", 0.0) or 0.0) * mm
                box_size_pt = float(layer.get("box_size_mm", 0.0) or 0.0) * mm
                row_height_pt = max(draw_height_pt, 20 * mm) + (10 * mm)

                if current_y - row_height_pt <= 16 * mm:
                    pdf.showPage()
                    current_y = start_page_header()

                image_x = margin_x + (4 * mm)
                image_y = current_y - draw_height_pt - (2 * mm)
                ProductionExportService._draw_pdf_printable_layer(
                    pdf=pdf,
                    layer=layer,
                    x_pt=image_x,
                    y_pt=image_y,
                    draw_width_pt=draw_width_pt,
                    draw_height_pt=draw_height_pt,
                    box_size_pt=box_size_pt,
                    image_cache=image_cache,
                )

                info_x = image_x + max(draw_width_pt, 32 * mm) + (10 * mm)
                info_y = current_y - (1 * mm)
                pdf.setFont("Helvetica-Bold", 9)
                pdf.setFillColor(colors.HexColor("#111827"))
                pdf.drawString(info_x, info_y, layer.get("sticker_name") or "Sticker")
                pdf.setFont("Helvetica", 8.5)
                info_y -= 4.5 * mm
                for line in [
                    f"Sticker ID: {layer.get('sticker_id') or '-'}",
                    f"Actual size: {layer.get('render_width_mm')} x {layer.get('render_height_mm')} mm",
                    f"Placement: {layer.get('position_label')}",
                    f"Rotation on helmet: {layer.get('rotation_degrees')} deg",
                ]:
                    pdf.drawString(info_x, info_y, line)
                    info_y -= 4.2 * mm

                current_y -= row_height_pt

            current_y -= 2 * mm

    @staticmethod
    def _draw_pdf_printable_layer(
        pdf: canvas.Canvas,
        layer: dict[str, Any],
        x_pt: float,
        y_pt: float,
        draw_width_pt: float,
        draw_height_pt: float,
        box_size_pt: float,
        image_cache: dict[str, dict[str, Any]],
    ) -> None:
        pdf.saveState()
        pdf.setStrokeColor(colors.HexColor("#D1D5DB"))
        pdf.setDash(3, 2)
        pdf.rect(x_pt, y_pt, draw_width_pt, draw_height_pt, stroke=1, fill=0)
        pdf.setDash()
        pdf.restoreState()

        asset = ProductionExportService._load_image_asset(layer.get("image_url"), image_cache)
        if not asset:
            pdf.setFont("Helvetica", 8)
            pdf.setFillColor(colors.HexColor("#6B7280"))
            pdf.drawString(x_pt + 4, y_pt + draw_height_pt - 10, "Image unavailable")
            return

        crop = layer.get("crop") or {}
        crop_left = float(crop.get("left", 0.0) or 0.0)
        crop_bottom = float(crop.get("bottom", 1.0) or 1.0)

        full_x = x_pt - (crop_left * box_size_pt)
        full_y = y_pt - ((1.0 - crop_bottom) * box_size_pt)

        pdf.saveState()
        clip_path = pdf.beginPath()
        clip_path.rect(x_pt, y_pt, draw_width_pt, draw_height_pt)
        pdf.clipPath(clip_path, stroke=0, fill=0)
        pdf.drawImage(
            asset["reader"],
            full_x,
            full_y,
            width=box_size_pt,
            height=box_size_pt,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )
        pdf.restoreState()

    @staticmethod
    def _render_svg(payload: dict[str, Any]) -> str:
        image_cache: dict[str, dict[str, Any]] = {}
        defs: list[str] = []
        body: list[str] = []
        width_mm = ProductionExportService.PAGE_WIDTH_MM
        margin_mm = 14.0
        current_y_mm = 16.0
        clip_counter = 0

        body.append(
            f'<text x="{margin_mm}" y="{current_y_mm}" font-size="6" font-weight="700" fill="#111827">'
            f'Order #{payload.get("order_id")} Sticker Print Sheet'
            "</text>"
        )
        current_y_mm += 8.0

        for item in payload.get("items") or []:
            item_title = html.escape(item.get("product_name") or "Helmet design")
            body.append(
                f'<text x="{margin_mm}" y="{current_y_mm}" font-size="4.5" font-weight="700" fill="#111827">'
                f"{item_title} - quantity {item.get('quantity')}"
                "</text>"
            )
            current_y_mm += 6.0

            for copy_index in range(int(item.get("quantity", 0) or 0)):
                body.append(
                    f'<text x="{margin_mm}" y="{current_y_mm}" font-size="4" fill="#374151">'
                    f"Copy set {copy_index + 1}/{item.get('quantity')}"
                    "</text>"
                )
                current_y_mm += 5.0

                for layer in item.get("layers") or []:
                    draw_width_mm = float(layer.get("render_width_mm", 0.0) or 0.0)
                    draw_height_mm = float(layer.get("render_height_mm", 0.0) or 0.0)
                    box_size_mm = float(layer.get("box_size_mm", 0.0) or 0.0)
                    image_x_mm = margin_mm + 4.0
                    image_y_mm = current_y_mm
                    info_x_mm = image_x_mm + max(draw_width_mm, 32.0) + 8.0

                    body.append(
                        f'<rect x="{image_x_mm}" y="{image_y_mm}" width="{draw_width_mm}" height="{draw_height_mm}" '
                        'fill="none" stroke="#D1D5DB" stroke-dasharray="2 1.5" />'
                    )

                    image_tag = ProductionExportService._build_svg_image_tag(
                        layer=layer,
                        x_mm=image_x_mm,
                        y_mm=image_y_mm,
                        draw_width_mm=draw_width_mm,
                        draw_height_mm=draw_height_mm,
                        box_size_mm=box_size_mm,
                        clip_id=f"clip-{clip_counter}",
                        defs=defs,
                        image_cache=image_cache,
                    )
                    clip_counter += 1
                    if image_tag:
                        body.append(image_tag)

                    name = html.escape(layer.get("sticker_name") or "Sticker")
                    lines = [
                        name,
                        f"Sticker ID: {layer.get('sticker_id') or '-'}",
                        f"Actual size: {layer.get('render_width_mm')} x {layer.get('render_height_mm')} mm",
                        f"Placement: {html.escape(layer.get('position_label') or '-')} | rotation {layer.get('rotation_degrees')} deg",
                    ]
                    for idx, line in enumerate(lines):
                        weight = "700" if idx == 0 else "400"
                        body.append(
                            f'<text x="{info_x_mm}" y="{image_y_mm + 4.5 + (idx * 4.5)}" '
                            f'font-size="3.8" font-weight="{weight}" fill="#111827">{html.escape(line)}</text>'
                        )

                    current_y_mm += max(draw_height_mm, 20.0) + 8.0

                current_y_mm += 2.0

            current_y_mm += 3.0

        total_height_mm = max(current_y_mm + 12.0, ProductionExportService.PAGE_HEIGHT_MM)
        defs_markup = f"<defs>{''.join(defs)}</defs>" if defs else ""
        return (
            '<?xml version="1.0" encoding="UTF-8"?>'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width_mm}mm" height="{total_height_mm}mm" '
            f'viewBox="0 0 {width_mm} {total_height_mm}">'
            f"{defs_markup}"
            '<rect x="0" y="0" width="100%" height="100%" fill="#FFFFFF" />'
            f"{''.join(body)}"
            "</svg>"
        )

    @staticmethod
    def _build_svg_image_tag(
        layer: dict[str, Any],
        x_mm: float,
        y_mm: float,
        draw_width_mm: float,
        draw_height_mm: float,
        box_size_mm: float,
        clip_id: str,
        defs: list[str],
        image_cache: dict[str, dict[str, Any]],
    ) -> Optional[str]:
        href = ProductionExportService._svg_href(layer.get("image_url"), image_cache)
        if not href:
            return None

        crop = layer.get("crop") or {}
        crop_left = float(crop.get("left", 0.0) or 0.0)
        crop_bottom = float(crop.get("bottom", 1.0) or 1.0)
        full_x = x_mm - (crop_left * box_size_mm)
        full_y = y_mm - ((1.0 - crop_bottom) * box_size_mm)

        defs.append(
            f'<clipPath id="{clip_id}"><rect x="{x_mm}" y="{y_mm}" width="{draw_width_mm}" height="{draw_height_mm}" /></clipPath>'
        )
        return (
            f'<image href="{href}" x="{full_x}" y="{full_y}" width="{box_size_mm}" height="{box_size_mm}" '
            f'preserveAspectRatio="xMidYMid meet" clip-path="url(#{clip_id})" />'
        )

    @staticmethod
    def _svg_href(
        source: Optional[str],
        image_cache: dict[str, dict[str, Any]],
    ) -> Optional[str]:
        asset = ProductionExportService._load_image_asset(source, image_cache)
        if not asset:
            return None

        encoded = base64.b64encode(asset["bytes"]).decode("ascii")
        return f"data:{asset['mime_type']};base64,{encoded}"
