"""remove model_3d fields from products

Revision ID: d1f2e3a4b5c6
Revises: 21b3e0a8869c
Create Date: 2026-04-03 14:45:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "d1f2e3a4b5c6"
down_revision: Union[str, Sequence[str], None] = "21b3e0a8869c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(inspector, table_name: str, column_name: str) -> bool:
    return any(column["name"] == column_name for column in inspector.get_columns(table_name))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if _has_column(inspector, "products", "model_3d_public_id"):
        op.drop_column("products", "model_3d_public_id")
        inspector = sa.inspect(bind)
    if _has_column(inspector, "products", "model_3d_url"):
        op.drop_column("products", "model_3d_url")


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not _has_column(inspector, "products", "model_3d_url"):
        op.add_column("products", sa.Column("model_3d_url", sa.Text(), nullable=True))
        inspector = sa.inspect(bind)
    if not _has_column(inspector, "products", "model_3d_public_id"):
        op.add_column("products", sa.Column("model_3d_public_id", sa.String(length=255), nullable=True))
