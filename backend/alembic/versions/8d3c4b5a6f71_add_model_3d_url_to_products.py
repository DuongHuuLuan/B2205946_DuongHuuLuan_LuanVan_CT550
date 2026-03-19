"""add model_3d fields to products

Revision ID: 8d3c4b5a6f71
Revises: 7b2c1d4e5f60
Create Date: 2026-03-18 16:30:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "8d3c4b5a6f71"
down_revision: Union[str, Sequence[str], None] = "7b2c1d4e5f60"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(inspector, table_name: str, column_name: str) -> bool:
    return any(column["name"] == column_name for column in inspector.get_columns(table_name))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not _has_column(inspector, "products", "model_3d_url"):
        op.add_column("products", sa.Column("model_3d_url", sa.Text(), nullable=True))
        inspector = sa.inspect(bind)
    if not _has_column(inspector, "products", "model_3d_public_id"):
        op.add_column("products", sa.Column("model_3d_public_id", sa.String(length=255), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if _has_column(inspector, "products", "model_3d_url"):
        op.drop_column("products", "model_3d_url")
        inspector = sa.inspect(bind)
    if _has_column(inspector, "products", "model_3d_public_id"):
        op.drop_column("products", "model_3d_public_id")
