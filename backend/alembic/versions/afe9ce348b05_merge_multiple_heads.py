"""merge multiple heads

Revision ID: afe9ce348b05
Revises: f3b7c1a2d4e5, e25f1c4a9b10
Create Date: 2026-02-25 14:58:58.937572

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'afe9ce348b05'
down_revision: Union[str, Sequence[str], None] = ('f3b7c1a2d4e5', 'e25f1c4a9b10')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
