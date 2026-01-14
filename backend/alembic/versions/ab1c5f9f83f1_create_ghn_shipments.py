"""create ghn_shipments table

Revision ID: ab1c5f9f83f1
Revises: 9c1f0d0b7a2d
Create Date: 2026-01-14 00:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "ab1c5f9f83f1"
down_revision: Union[str, Sequence[str], None] = "9c1f0d0b7a2d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "ghn_shipments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("order_id", sa.Integer(), nullable=True),
        sa.Column("ghn_order_code", sa.String(length=64), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=True),
        sa.Column("service_id", sa.Integer(), nullable=True),
        sa.Column("service_type_id", sa.Integer(), nullable=True),
        sa.Column("from_name", sa.String(length=255), nullable=True),
        sa.Column("from_phone", sa.String(length=20), nullable=True),
        sa.Column("from_address", sa.String(length=255), nullable=True),
        sa.Column("from_ward_code", sa.String(length=20), nullable=True),
        sa.Column("from_district_id", sa.Integer(), nullable=True),
        sa.Column("to_name", sa.String(length=255), nullable=True),
        sa.Column("to_phone", sa.String(length=20), nullable=True),
        sa.Column("to_address", sa.String(length=255), nullable=True),
        sa.Column("to_ward_code", sa.String(length=20), nullable=True),
        sa.Column("to_district_id", sa.Integer(), nullable=True),
        sa.Column("weight", sa.Integer(), nullable=True),
        sa.Column("length", sa.Integer(), nullable=True),
        sa.Column("width", sa.Integer(), nullable=True),
        sa.Column("height", sa.Integer(), nullable=True),
        sa.Column("cod_amount", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("insurance_value", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("shipping_fee", sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column("expected_delivery_time", sa.String(length=64), nullable=True),
        sa.Column("leadtime", sa.String(length=64), nullable=True),
        sa.Column("tracking_url", sa.String(length=255), nullable=True),
        sa.Column("note", sa.String(length=255), nullable=True),
        sa.Column("raw_request", sa.Text(), nullable=True),
        sa.Column("raw_response", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_ghn_shipments_id"), "ghn_shipments", ["id"], unique=False)
    op.create_index(op.f("ix_ghn_shipments_order_id"), "ghn_shipments", ["order_id"], unique=False)
    op.create_index(op.f("ix_ghn_shipments_ghn_order_code"), "ghn_shipments", ["ghn_order_code"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_ghn_shipments_ghn_order_code"), table_name="ghn_shipments")
    op.drop_index(op.f("ix_ghn_shipments_order_id"), table_name="ghn_shipments")
    op.drop_index(op.f("ix_ghn_shipments_id"), table_name="ghn_shipments")
    op.drop_table("ghn_shipments")
