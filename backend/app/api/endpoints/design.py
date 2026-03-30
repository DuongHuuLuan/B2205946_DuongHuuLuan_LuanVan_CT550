from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import require_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.design import (
    DesignCreate,
    DesignListOut,
    DesignOrderIn,
    DesignOrderOut,
    DesignOut,
    DesignShareOut,
    DesignUpdate,
)
from app.services.design_service import DesignService

router = APIRouter(prefix="/designs", tags=["Designs"])


@router.post("/", response_model=DesignOut, status_code=status.HTTP_201_CREATED)
def create_design(
    design_in: DesignCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return DesignService.create_design(db, current_user.id, design_in)


@router.put("/{design_id}", response_model=DesignOut)
def update_design(
    design_id: int,
    design_in: DesignUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return DesignService.update_design(db, design_id, current_user.id, design_in)

@router.get("/my-designs", response_model=DesignListOut)
def get_my_designs(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    designs = DesignService.get_my_designs(db, current_user.id)
    return DesignListOut(items=designs)


@router.get("/{design_id}", response_model=DesignOut)
def get_design_detail(
    design_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return DesignService.get_design_detail(db, design_id, current_user.id)


@router.post("/{design_id}/share", response_model=DesignShareOut)
def create_design_share_link(
    design_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return DesignService.create_share_link(db, design_id, current_user.id)


@router.post("/{design_id}/order", response_model=DesignOrderOut)
def order_design(
    design_id: int,
    order_in: DesignOrderIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_user),
):
    return DesignService.order_design(db, design_id, current_user.id, order_in)
