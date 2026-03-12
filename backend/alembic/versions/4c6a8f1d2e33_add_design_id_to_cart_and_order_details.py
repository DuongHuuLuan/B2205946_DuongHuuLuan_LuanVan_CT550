"""add design_id to cart_details and order_details

Revision ID: 4c6a8f1d2e33
Revises: 2a5d6c0e9f11
Create Date: 2026-03-12 16:20:00
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "4c6a8f1d2e33"
down_revision = "2a5d6c0e9f11"
branch_labels = None
depends_on = None


def _has_column(inspector, table_name: str, column_name: str) -> bool:
    return any(column["name"] == column_name for column in inspector.get_columns(table_name))


def _has_index(inspector, table_name: str, index_name: str) -> bool:
    return any(index["name"] == index_name for index in inspector.get_indexes(table_name))


def _has_fk(inspector, table_name: str, fk_name: str) -> bool:
    return any(fk["name"] == fk_name for fk in inspector.get_foreign_keys(table_name))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not _has_column(inspector, "cart_details", "design_id"):
        op.add_column("cart_details", sa.Column("design_id", sa.Integer(), nullable=True))
        inspector = sa.inspect(bind)
    if not _has_index(inspector, "cart_details", "ix_cart_details_design_id"):
        op.create_index("ix_cart_details_design_id", "cart_details", ["design_id"], unique=False)
        inspector = sa.inspect(bind)
    if not _has_fk(inspector, "cart_details", "fk_cart_details_design_id_designs"):
        op.create_foreign_key(
            "fk_cart_details_design_id_designs",
            "cart_details",
            "designs",
            ["design_id"],
            ["id"],
            ondelete="SET NULL",
        )
        inspector = sa.inspect(bind)

    if not _has_column(inspector, "order_details", "design_id"):
        op.add_column("order_details", sa.Column("design_id", sa.Integer(), nullable=True))
        inspector = sa.inspect(bind)
    if not _has_index(inspector, "order_details", "ix_order_details_design_id"):
        op.create_index("ix_order_details_design_id", "order_details", ["design_id"], unique=False)
        inspector = sa.inspect(bind)
    if not _has_fk(inspector, "order_details", "fk_order_details_design_id_designs"):
        op.create_foreign_key(
            "fk_order_details_design_id_designs",
            "order_details",
            "designs",
            ["design_id"],
            ["id"],
            ondelete="SET NULL",
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if _has_fk(inspector, "order_details", "fk_order_details_design_id_designs"):
        op.drop_constraint("fk_order_details_design_id_designs", "order_details", type_="foreignkey")
        inspector = sa.inspect(bind)
    if _has_index(inspector, "order_details", "ix_order_details_design_id"):
        op.drop_index("ix_order_details_design_id", table_name="order_details")
        inspector = sa.inspect(bind)
    if _has_column(inspector, "order_details", "design_id"):
        op.drop_column("order_details", "design_id")
        inspector = sa.inspect(bind)

    if _has_fk(inspector, "cart_details", "fk_cart_details_design_id_designs"):
        op.drop_constraint("fk_cart_details_design_id_designs", "cart_details", type_="foreignkey")
        inspector = sa.inspect(bind)
    if _has_index(inspector, "cart_details", "ix_cart_details_design_id"):
        op.drop_index("ix_cart_details_design_id", table_name="cart_details")
        inspector = sa.inspect(bind)
    if _has_column(inspector, "cart_details", "design_id"):
        op.drop_column("cart_details", "design_id")
