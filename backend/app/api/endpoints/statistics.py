from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.api.deps import require_admin
from app.db.session import get_db
from app.models.user import User
from app.schemas.statistics import (
    StatisticsAlertsOut,
    StatisticsFilterParams,
    StatisticsOrderMixOut,
    StatisticsOrderStatus,
    StatisticsOverviewOut,
    StatisticsPaymentMixOut,
    StatisticsRange,
    StatisticsRevenueSeriesOut,
    StatisticsReviewsSummaryOut,
    StatisticsScope,
    StatisticsTopProductsOut,
)
from app.services.statistics_service import StatisticsService
from app.services.statistics_export_service import StatisticsExportService

router = APIRouter(prefix="/statistics", tags=["Statistics"])


def get_statistics_filters(
    range: StatisticsRange = Query(StatisticsRange.LAST_30_DAYS),
    order_status: StatisticsOrderStatus = Query(StatisticsOrderStatus.ALL),
    scope: StatisticsScope = Query(StatisticsScope.OVERVIEW),
) -> StatisticsFilterParams:
    return StatisticsFilterParams(
        range=range,
        order_status=order_status,
        scope=scope,
    )


@router.get("/overview", response_model=StatisticsOverviewOut)
def get_overview(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_overview(db, filters)


@router.get("/revenue-series", response_model=StatisticsRevenueSeriesOut)
def get_revenue_series(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_revenue_series(db, filters)


@router.get("/order-mix", response_model=StatisticsOrderMixOut)
def get_order_mix(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_order_mix(db, filters)


@router.get("/top-products", response_model=StatisticsTopProductsOut)
def get_top_products(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_top_products(db, filters)


@router.get("/payment-mix", response_model=StatisticsPaymentMixOut)
def get_payment_mix(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_payment_mix(db, filters)


@router.get("/reviews-summary", response_model=StatisticsReviewsSummaryOut)
def get_reviews_summary(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_reviews_summary(db, filters)


@router.get("/alerts", response_model=StatisticsAlertsOut)
def get_alerts(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    return StatisticsService.get_alerts(db, filters)


@router.get("/export/pdf")
def export_statistics_pdf(
    filters: StatisticsFilterParams = Depends(get_statistics_filters),
    db: Session = Depends(get_db),
    current_admin: User = Depends(require_admin),
):
    pdf_bytes, filename = StatisticsExportService.export_pdf(db, filters)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
