"""add district_id and ward_code to delivery_info

Revision ID: c2f3b6a9d5e4
Revises: ab1c5f9f83f1
Create Date: 2026-01-15 00:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c2f3b6a9d5e4"
down_revision: Union[str, Sequence[str], None] = "ab1c5f9f83f1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("delivery_info", sa.Column("district_id", sa.Integer(), nullable=True))
    op.add_column("delivery_info", sa.Column("ward_code", sa.String(length=20), nullable=True))


def downgrade() -> None:
    op.drop_column("delivery_info", "ward_code")
    op.drop_column("delivery_info", "district_id")
