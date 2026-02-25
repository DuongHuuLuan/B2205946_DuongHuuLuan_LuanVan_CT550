"""add avatar_public_id to profiles

Revision ID: f3b7c1a2d4e5
Revises: c2f3b6a9d5e4
Create Date: 2026-02-25 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f3b7c1a2d4e5"
down_revision: Union[str, Sequence[str], None] = "c2f3b6a9d5e4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("profiles", sa.Column("avatar_public_id", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("profiles", "avatar_public_id")
