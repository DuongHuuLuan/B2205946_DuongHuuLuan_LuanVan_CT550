"""add read state to conversations

Revision ID: 6f4d0f8b2c31
Revises: 51d8ac988a6f
Create Date: 2026-03-07 11:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "6f4d0f8b2c31"
down_revision: Union[str, Sequence[str], None] = "51d8ac988a6f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("conversations", sa.Column("last_read_user_message_id", sa.Integer(), nullable=True))
    op.add_column("conversations", sa.Column("last_read_admin_message_id", sa.Integer(), nullable=True))

    op.create_index(
        op.f("ix_conversations_last_read_user_message_id"),
        "conversations",
        ["last_read_user_message_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_conversations_last_read_admin_message_id"),
        "conversations",
        ["last_read_admin_message_id"],
        unique=False,
    )

    op.create_foreign_key(
        "fk_conversations_last_read_user_message_id_messages",
        "conversations",
        "messages",
        ["last_read_user_message_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_conversations_last_read_admin_message_id_messages",
        "conversations",
        "messages",
        ["last_read_admin_message_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_conversations_last_read_admin_message_id_messages",
        "conversations",
        type_="foreignkey",
    )
    op.drop_constraint(
        "fk_conversations_last_read_user_message_id_messages",
        "conversations",
        type_="foreignkey",
    )

    op.drop_index(
        op.f("ix_conversations_last_read_admin_message_id"),
        table_name="conversations",
    )
    op.drop_index(
        op.f("ix_conversations_last_read_user_message_id"),
        table_name="conversations",
    )

    op.drop_column("conversations", "last_read_admin_message_id")
    op.drop_column("conversations", "last_read_user_message_id")
