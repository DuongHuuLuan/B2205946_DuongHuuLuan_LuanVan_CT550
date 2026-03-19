"""add view_image_key to image_url

Revision ID: 9f4a2b1c6d80
Revises: 8d3c4b5a6f71
Create Date: 2026-03-19 21:05:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "9f4a2b1c6d80"
down_revision: Union[str, Sequence[str], None] = "8d3c4b5a6f71"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(inspector, table_name: str, column_name: str) -> bool:
    return any(column["name"] == column_name for column in inspector.get_columns(table_name))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not _has_column(inspector, "image_url", "view_image_key"):
        op.add_column("image_url", sa.Column("view_image_key", sa.String(length=50), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if _has_column(inspector, "image_url", "view_image_key"):
        op.drop_column("image_url", "view_image_key")
