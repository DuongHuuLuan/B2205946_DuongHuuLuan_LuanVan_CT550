"""add order review payment and snapshot fields

Revision ID: 7b2c1d4e5f60
Revises: 4c6a8f1d2e33
Create Date: 2026-03-14 00:15:00
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "7b2c1d4e5f60"
down_revision = "4c6a8f1d2e33"
branch_labels = None
depends_on = None


def _has_column(inspector, table_name: str, column_name: str) -> bool:
    return any(column["name"] == column_name for column in inspector.get_columns(table_name))


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    payment_status_enum = sa.Enum("unpaid", "paid", name="paymentstatus")
    refund_support_status_enum = sa.Enum(
        "none",
        "contact_required",
        "resolved",
        name="refundsupportstatus",
    )
    payment_status_enum.create(bind, checkfirst=True)
    refund_support_status_enum.create(bind, checkfirst=True)

    if not _has_column(inspector, "orders", "payment_status"):
        op.add_column(
            "orders",
            sa.Column(
                "payment_status",
                payment_status_enum,
                nullable=False,
                server_default="unpaid",
            ),
        )
        inspector = sa.inspect(bind)

    if not _has_column(inspector, "orders", "refund_support_status"):
        op.add_column(
            "orders",
            sa.Column(
                "refund_support_status",
                refund_support_status_enum,
                nullable=False,
                server_default="none",
            ),
        )
        inspector = sa.inspect(bind)

    if not _has_column(inspector, "orders", "rejection_reason"):
        op.add_column("orders", sa.Column("rejection_reason", sa.String(length=500), nullable=True))
        inspector = sa.inspect(bind)

    if not _has_column(inspector, "orders", "reviewed_by_admin_id"):
        op.add_column("orders", sa.Column("reviewed_by_admin_id", sa.Integer(), nullable=True))
        op.create_foreign_key(
            "fk_orders_reviewed_by_admin_id_users",
            "orders",
            "users",
            ["reviewed_by_admin_id"],
            ["id"],
        )
        inspector = sa.inspect(bind)

    if not _has_column(inspector, "orders", "reviewed_at"):
        op.add_column("orders", sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True))
        inspector = sa.inspect(bind)

    if not _has_column(inspector, "order_details", "design_snapshot_json"):
        op.add_column("order_details", sa.Column("design_snapshot_json", sa.JSON(), nullable=True))

    op.alter_column("orders", "payment_status", server_default=None)
    op.alter_column("orders", "refund_support_status", server_default=None)


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if _has_column(inspector, "order_details", "design_snapshot_json"):
        op.drop_column("order_details", "design_snapshot_json")
        inspector = sa.inspect(bind)

    if _has_column(inspector, "orders", "reviewed_at"):
        op.drop_column("orders", "reviewed_at")
        inspector = sa.inspect(bind)

    if _has_column(inspector, "orders", "reviewed_by_admin_id"):
        op.drop_constraint("fk_orders_reviewed_by_admin_id_users", "orders", type_="foreignkey")
        op.drop_column("orders", "reviewed_by_admin_id")
        inspector = sa.inspect(bind)

    if _has_column(inspector, "orders", "rejection_reason"):
        op.drop_column("orders", "rejection_reason")
        inspector = sa.inspect(bind)

    if _has_column(inspector, "orders", "refund_support_status"):
        op.drop_column("orders", "refund_support_status")
        inspector = sa.inspect(bind)

    if _has_column(inspector, "orders", "payment_status"):
        op.drop_column("orders", "payment_status")

    sa.Enum(name="refundsupportstatus").drop(bind, checkfirst=True)
    sa.Enum(name="paymentstatus").drop(bind, checkfirst=True)
