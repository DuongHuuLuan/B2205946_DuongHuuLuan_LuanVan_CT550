"""add public_id to evaluate_images

Revision ID: c4e8f9a1b2d3
Revises: b9d6c1e4f8a2
Create Date: 2026-03-21
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c4e8f9a1b2d3"
down_revision: Union[str, Sequence[str], None] = "b9d6c1e4f8a2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("evaluate_images", sa.Column("public_id", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("evaluate_images", "public_id")
