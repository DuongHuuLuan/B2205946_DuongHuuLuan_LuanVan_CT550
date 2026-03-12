"""add public_id to stickers

Revision ID: 2a5d6c0e9f11
Revises: 1732b96834fc
Create Date: 2026-03-12 16:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "2a5d6c0e9f11"
down_revision: Union[str, Sequence[str], None] = "1732b96834fc"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _column_exists(table_name: str, column_name: str) -> bool:
    inspector = sa.inspect(op.get_bind())
    columns = inspector.get_columns(table_name)
    return any(column["name"] == column_name for column in columns)


def upgrade() -> None:
    if _column_exists("stickers", "public_id"):
        return

    op.add_column(
        "stickers",
        sa.Column("public_id", sa.String(length=255), nullable=True),
    )
    op.execute(
        """
        UPDATE stickers
        SET public_id = CONCAT('legacy/stickers/', id)
        WHERE public_id IS NULL OR public_id = ''
        """
    )
    op.alter_column("stickers", "public_id", existing_type=sa.String(length=255), nullable=False)


def downgrade() -> None:
    if _column_exists("stickers", "public_id"):
        op.drop_column("stickers", "public_id")
