from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Optional

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy.orm import Session

from app.schemas.statistics import StatisticsFilterParams, StatisticsScope
from app.services.statistics_service import StatisticsService


class StatisticsExportService:
    RANGE_LABELS = {
        "7d": "7 ngày gần nhất",
        "30d": "30 ngày gần nhất",
        "month": "Tháng này",
        "quarter": "Quý này",
    }

    _fonts_registered = False
    _font_regular = "Helvetica"
    _font_bold = "Helvetica-Bold"

    @staticmethod
    def export_pdf(db: Session, filters: StatisticsFilterParams) -> tuple[bytes, str]:
        snapshot = StatisticsExportService._build_snapshot(db, filters)
        pdf_bytes = StatisticsExportService._render_pdf(snapshot)
        timestamp = datetime.now().strftime("%Y%m%d-%H%M")
        filename = f"thong-ke-{filters.scope.value}-{timestamp}.pdf"
        return pdf_bytes, filename

    @staticmethod
    def _build_snapshot(db: Session, filters: StatisticsFilterParams) -> dict:
        scope = filters.scope
        show_sales = scope != StatisticsScope.REVIEWS
        show_reviews = scope != StatisticsScope.SALES

        overview = StatisticsService.get_overview(db, filters)
        alerts = StatisticsService.get_alerts(db, filters)
        payment_mix = StatisticsService.get_payment_mix(db, filters)["items"] if show_sales else []
        review_summary = StatisticsService.get_reviews_summary(db, filters) if show_reviews else None

        sections = [
            {
                "title": "KPI Tổng quan",
                "columns": ["Chỉ số", "Giá trị"],
                "rows": StatisticsExportService._build_kpi_rows(
                    overview=overview,
                    show_sales=show_sales,
                    show_reviews=show_reviews,
                    payment_mix=payment_mix,
                    review_summary=review_summary,
                ),
            }
        ]

        if show_sales:
            revenue_series = StatisticsService.get_revenue_series(db, filters)
            order_mix = StatisticsService.get_order_mix(db, filters)
            top_products = StatisticsService.get_top_products(db, filters)

            sections.extend(
                [
                    {
                        "title": "Xu hướng doanh thu",
                        "columns": ["Mốc thời gian", "Doanh thu"],
                        "rows": [
                            [item["label"], StatisticsExportService._money(item["value"])]
                            for item in revenue_series["items"]
                        ],
                    },
                    {
                        "title": "Cơ cấu đơn hàng",
                        "columns": ["Trạng thái", "Số đơn", "Tỉ lệ"],
                        "rows": [
                            [item["label"], str(item["count"]), f'{item["share"]}%']
                            for item in order_mix["items"]
                        ],
                    },
                    {
                        "title": "Top sản phẩm bán chạy",
                        "columns": ["Sản phẩm", "Danh mục", "Đã bán", "Doanh thu", "Ghi chú"],
                        "rows": [
                            [
                                item["name"],
                                item["category"],
                                str(item["sold"]),
                                StatisticsExportService._money(item["revenue"]),
                                item.get("note") or "-",
                            ]
                            for item in top_products["items"]
                        ],
                    },
                    {
                        "title": "Phương thức thanh toán",
                        "columns": ["Phương thức", "Số đơn", "Tỉ lệ", "Doanh thu"],
                        "rows": [
                            [
                                item["label"],
                                str(item["count"]),
                                f'{item["share"]}%',
                                StatisticsExportService._money(item["revenue"]),
                            ]
                            for item in payment_mix
                        ],
                    },
                ]
            )

        if show_reviews and review_summary is not None:
            positive_share = StatisticsExportService._positive_review_share(review_summary["items"])
            sections.extend(
                [
                    {
                        "title": "Tổng quan đánh giá",
                        "columns": ["Chỉ số", "Giá trị"],
                        "rows": [
                            ["Tổng số đánh giá", str(review_summary["total_reviews"])],
                            ["Điểm trung bình", f'{review_summary["average_rating"]:.1f}'],
                            ["Chờ phản hồi", str(review_summary["pending_replies"])],
                            ["Tỉ lệ 4-5 sao", f"{positive_share}%"],
                            ["Đánh giá 1-2 sao", str(StatisticsExportService._low_rating_count(review_summary["items"]))],
                        ],
                    },
                    {
                        "title": "Phân bổ 1-5 sao",
                        "columns": ["Mức sao", "Số lượng", "Tỉ lệ"],
                        "rows": [
                            [f'{item["rate"]} sao', str(item["count"]), f'{item["share"]}%']
                            for item in review_summary["items"]
                        ],
                    },
                ]
            )

        sections.append(
            {
                "title": "Cảnh báo vận hành",
                "columns": ["Tiêu đề", "Mô tả", "Hành động"],
                "rows": [
                    [item["title"], item["text"], item["action"]]
                    for item in alerts["items"]
                ],
            }
        )

        return {
            "title": "BÁO CÁO THỐNG KÊ QUẢN TRỊ",
            "scope_label": StatisticsExportService._scope_label(scope),
            "range_label": StatisticsExportService.RANGE_LABELS.get(filters.range.value, filters.range.value),
            "generated_at": datetime.now().strftime("%d/%m/%Y %H:%M"),
            "subtitle": StatisticsExportService._subtitle(filters),
            "sections": sections,
        }

    @staticmethod
    def _build_kpi_rows(
        overview: dict,
        show_sales: bool,
        show_reviews: bool,
        payment_mix: list[dict],
        review_summary: Optional[dict],
    ) -> list[list[str]]:
        rows: list[list[str]] = []

        if show_sales:
            top_payment = payment_mix[0] if payment_mix else {"label": "--", "share": 0}
            rows.extend(
                [
                    ["Doanh thu", StatisticsExportService._money(overview["revenue"])],
                    ["Đơn hàng", str(overview["orders"])],
                    ["Giá trị đơn TB", StatisticsExportService._money(overview["average_order_value"])],
                    ["Tỉ lệ hoàn tất", f'{overview["completion_rate"]}%'],
                    ["Đơn chờ xác nhận", str(overview["pending_orders"])],
                    ["PTTT chính", f'{top_payment["label"]} ({top_payment["share"]}%)'],
                ]
            )

        if show_reviews and review_summary is not None:
            rows.extend(
                [
                    ["Tổng đánh giá", str(review_summary["total_reviews"])],
                    ["Điểm trung bình", f'{review_summary["average_rating"]:.1f}'],
                    ["Chờ phản hồi", str(review_summary["pending_replies"])],
                    ["Tỉ lệ 4-5 sao", f'{StatisticsExportService._positive_review_share(review_summary["items"])}%'],
                    ["Đánh giá 1-2 sao", str(StatisticsExportService._low_rating_count(review_summary["items"]))],
                ]
            )

        return rows

    @staticmethod
    def _render_pdf(snapshot: dict) -> bytes:
        StatisticsExportService._ensure_fonts()
        regular_font = StatisticsExportService._font_regular
        bold_font = StatisticsExportService._font_bold

        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            "StatisticsTitle",
            parent=styles["Heading1"],
            fontName=bold_font,
            fontSize=18,
            leading=24,
            textColor=colors.HexColor("#111827"),
            spaceAfter=10,
        )
        meta_style = ParagraphStyle(
            "StatisticsMeta",
            parent=styles["BodyText"],
            fontName=regular_font,
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#4B5563"),
            spaceAfter=4,
        )
        section_style = ParagraphStyle(
            "StatisticsSection",
            parent=styles["Heading2"],
            fontName=bold_font,
            fontSize=13,
            leading=18,
            textColor=colors.HexColor("#111827"),
            spaceBefore=8,
            spaceAfter=8,
        )
        cell_style = ParagraphStyle(
            "StatisticsCell",
            parent=styles["BodyText"],
            fontName=regular_font,
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#111827"),
        )
        header_style = ParagraphStyle(
            "StatisticsHeaderCell",
            parent=cell_style,
            fontName=bold_font,
            textColor=colors.white,
        )

        story = [
            Paragraph(snapshot["title"], title_style),
            Paragraph(f'Phạm vi báo cáo: {snapshot["scope_label"]}', meta_style),
            Paragraph(f'Khoảng thời gian: {snapshot["range_label"]}', meta_style),
            Paragraph(f'Bộ lọc áp dụng: {snapshot["subtitle"]}', meta_style),
            Paragraph(f'Thời gian tạo: {snapshot["generated_at"]}', meta_style),
            Spacer(1, 10),
        ]

        for section in snapshot["sections"]:
            story.append(Paragraph(section["title"], section_style))
            story.append(
                StatisticsExportService._build_table(
                    section["columns"],
                    section["rows"],
                    header_style,
                    cell_style,
                )
            )
            story.append(Spacer(1, 10))

        buffer = BytesIO()
        document = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            leftMargin=14 * mm,
            rightMargin=14 * mm,
            topMargin=14 * mm,
            bottomMargin=14 * mm,
            title=snapshot["title"],
        )
        document.build(story)
        return buffer.getvalue()

    @staticmethod
    def _build_table(columns, rows, header_style, cell_style):
        normalized_rows = rows or [["Không có dữ liệu hiển thị"] + [""] * (len(columns) - 1)]
        table_data = [
            [Paragraph(str(column), header_style) for column in columns],
            *[
                [Paragraph(str(cell), cell_style) for cell in row]
                for row in normalized_rows
            ],
        ]

        column_count = max(len(columns), 1)
        available_width = A4[0] - (28 * mm)
        column_width = available_width / column_count
        table = Table(table_data, repeatRows=1, colWidths=[column_width] * column_count)
        table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F2937")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#D1D5DB")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 6),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9FAFB")]),
                ]
            )
        )
        return table

    @staticmethod
    def _ensure_fonts():
        if StatisticsExportService._fonts_registered:
            return

        regular_path, bold_path = StatisticsExportService._find_font_paths()
        if regular_path:
            pdfmetrics.registerFont(TTFont("StatisticsRegular", str(regular_path)))
            StatisticsExportService._font_regular = "StatisticsRegular"

        if bold_path:
            pdfmetrics.registerFont(TTFont("StatisticsBold", str(bold_path)))
            StatisticsExportService._font_bold = "StatisticsBold"
        elif regular_path:
            StatisticsExportService._font_bold = StatisticsExportService._font_regular

        StatisticsExportService._fonts_registered = True

    @staticmethod
    def _find_font_paths() -> tuple[Optional[Path], Optional[Path]]:
        static_dir = Path(__file__).resolve().parents[2] / "static" / "fonts"
        candidate_pairs = [
            (static_dir / "NotoSans-Regular.ttf", static_dir / "NotoSans-Bold.ttf"),
            (static_dir / "DejaVuSans.ttf", static_dir / "DejaVuSans-Bold.ttf"),
            (Path(r"C:\Windows\Fonts\arial.ttf"), Path(r"C:\Windows\Fonts\arialbd.ttf")),
            (
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
            ),
        ]

        for regular_path, bold_path in candidate_pairs:
            if regular_path.exists() and bold_path.exists():
                return regular_path, bold_path

        for regular_path, bold_path in candidate_pairs:
            if regular_path.exists():
                return regular_path, regular_path if not bold_path.exists() else bold_path

        return None, None

    @staticmethod
    def _money(value: float) -> str:
        return f"{float(value or 0):,.0f} VNĐ"

    @staticmethod
    def _positive_review_share(items: list[dict]) -> int:
        total = sum(int(item["count"]) for item in items) or 1
        positive = sum(int(item["count"]) for item in items if int(item["rate"]) >= 4)
        return round((positive / total) * 100)

    @staticmethod
    def _low_rating_count(items: list[dict]) -> int:
        return sum(int(item["count"]) for item in items if int(item["rate"]) <= 2)

    @staticmethod
    def _scope_label(scope: StatisticsScope) -> str:
        if scope == StatisticsScope.SALES:
            return "Bán hàng"
        if scope == StatisticsScope.REVIEWS:
            return "Đánh giá"
        return "Tổng quan"

    @staticmethod
    def _subtitle(filters: StatisticsFilterParams) -> str:
        order_status_label = {
            "all": "Tất cả trạng thái",
            "pending": "Chờ xác nhận",
            "shipping": "Đang giao",
            "completed": "Hoàn tất",
            "cancelled": "Đã hủy",
        }.get(filters.order_status.value, filters.order_status.value)

        scope_label = StatisticsExportService._scope_label(filters.scope)
        range_label = StatisticsExportService.RANGE_LABELS.get(filters.range.value, filters.range.value)
        return f"Đang xem {scope_label.lower()} trong {range_label.lower()}, lọc theo {order_status_label.lower()}."