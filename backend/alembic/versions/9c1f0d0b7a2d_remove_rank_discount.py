"""remove rank_discount from orders

Revision ID: 9c1f0d0b7a2d
Revises: 7eaf107e7586
Create Date: 2026-01-14 00:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "9c1f0d0b7a2d"
down_revision: Union[str, Sequence[str], None] = "7eaf107e7586"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("orders", "rank_discount")


def downgrade() -> None:
    op.add_column(
        "orders",
        sa.Column(
            "rank_discount",
            sa.Numeric(precision=10, scale=2),
            server_default=sa.text("0.0"),
            nullable=True,
        ),
    )
