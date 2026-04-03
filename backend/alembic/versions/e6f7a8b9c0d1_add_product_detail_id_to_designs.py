"""add product_detail_id to designs

Revision ID: e6f7a8b9c0d1
Revises: d1f2e3a4b5c6
Create Date: 2026-04-03 13:40:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e6f7a8b9c0d1"
down_revision: Union[str, Sequence[str], None] = "d1f2e3a4b5c6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(inspector, table_name: str, column_name: str) -> bool:
    return any(column["name"] == column_name for column in inspector.get_columns(table_name))


def _has_foreign_key(inspector, table_name: str, constraint_name: str) -> bool:
    return any(
        foreign_key.get("name") == constraint_name
        for foreign_key in inspector.get_foreign_keys(table_name)
    )


def _backfill_product_detail_id(bind) -> None:
    designs = sa.table(
        "designs",
        sa.column("id", sa.Integer),
        sa.column("product_detail_id", sa.Integer),
    )
    cart_details = sa.table(
        "cart_details",
        sa.column("design_id", sa.Integer),
        sa.column("product_detail_id", sa.Integer),
    )
    order_details = sa.table(
        "order_details",
        sa.column("design_id", sa.Integer),
        sa.column("product_detail_id", sa.Integer),
    )

    inferred_by_design: dict[int, set[int]] = {}
    for source in (cart_details, order_details):
        rows = bind.execute(
            sa.select(source.c.design_id, source.c.product_detail_id).where(
                source.c.design_id.isnot(None),
                source.c.product_detail_id.isnot(None),
            )
        )
        for design_id, product_detail_id in rows:
            if design_id is None or product_detail_id is None:
                continue
            inferred_by_design.setdefault(int(design_id), set()).add(
                int(product_detail_id)
            )

    for design_id, product_detail_ids in inferred_by_design.items():
        if len(product_detail_ids) != 1:
            continue
        bind.execute(
            sa.update(designs)
            .where(
                designs.c.id == design_id,
                designs.c.product_detail_id.is_(None),
            )
            .values(product_detail_id=next(iter(product_detail_ids)))
        )


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    constraint_name = "fk_designs_product_detail_id_product_details"

    if not _has_column(inspector, "designs", "product_detail_id"):
        op.add_column(
            "designs",
            sa.Column("product_detail_id", sa.Integer(), nullable=True),
        )

    inspector = sa.inspect(bind)
    if not _has_foreign_key(inspector, "designs", constraint_name):
        op.create_foreign_key(
            constraint_name,
            "designs",
            "product_details",
            ["product_detail_id"],
            ["id"],
            ondelete="SET NULL",
        )

    _backfill_product_detail_id(bind)


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    constraint_name = "fk_designs_product_detail_id_product_details"

    if _has_foreign_key(inspector, "designs", constraint_name):
        op.drop_constraint(constraint_name, "designs", type_="foreignkey")

    inspector = sa.inspect(bind)
    if _has_column(inspector, "designs", "product_detail_id"):
        op.drop_column("designs", "product_detail_id")
