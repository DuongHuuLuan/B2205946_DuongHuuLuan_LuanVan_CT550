"""add admin reply and evaluate images

Revision ID: e25f1c4a9b10
Revises: f0227cbaa8b1
Create Date: 2026-02-25
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e25f1c4a9b10"
down_revision: Union[str, Sequence[str], None] = "f0227cbaa8b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("evaluates", sa.Column("admin_id", sa.Integer(), nullable=True))
    op.add_column("evaluates", sa.Column("admin_reply", sa.Text(), nullable=True))
    op.add_column("evaluates", sa.Column("admin_replied_at", sa.DateTime(timezone=True), nullable=True))

    op.create_foreign_key(
        "fk_evaluates_admin_id_users",
        "evaluates",
        "users",
        ["admin_id"],
        ["id"],
        ondelete="SET NULL",
    )

    # Mỗi order chỉ 1 review
    op.create_unique_constraint("uq_evaluates_order_id", "evaluates", ["order_id"])

    op.create_table(
        "evaluate_images",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("evaluate_id", sa.Integer(), nullable=False),
        sa.Column("image_url", sa.String(length=255), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.ForeignKeyConstraint(["evaluate_id"], ["evaluates.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_evaluate_images_id"), "evaluate_images", ["id"], unique=False)
    op.create_index("ix_evaluate_images_evaluate_id", "evaluate_images", ["evaluate_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_evaluate_images_evaluate_id", table_name="evaluate_images")
    op.drop_index(op.f("ix_evaluate_images_id"), table_name="evaluate_images")
    op.drop_table("evaluate_images")

    op.drop_constraint("uq_evaluates_order_id", "evaluates", type_="unique")
    op.drop_constraint("fk_evaluates_admin_id_users", "evaluates", type_="foreignkey")

    op.drop_column("evaluates", "admin_replied_at")
    op.drop_column("evaluates", "admin_reply")
    op.drop_column("evaluates", "admin_id")
