"""add models design

Revision ID: 1732b96834fc
Revises: 6f4d0f8b2c31
Create Date: 2026-03-12 15:42:16.230526

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1732b96834fc'
down_revision: Union[str, Sequence[str], None] = '6f4d0f8b2c31'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _table_exists(table_name: str) -> bool:
    inspector = sa.inspect(op.get_bind())
    return table_name in inspector.get_table_names()


def _index_exists(table_name: str, index_name: str) -> bool:
    if not _table_exists(table_name):
        return False
    inspector = sa.inspect(op.get_bind())
    return any(index["name"] == index_name for index in inspector.get_indexes(table_name))


def upgrade() -> None:
    """Upgrade schema."""
    if not _table_exists('stickers'):
        op.create_table('stickers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('owner_user_id', sa.Integer(), nullable=True),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('image_url', sa.String(length=500), nullable=False),
        sa.Column('category', sa.String(length=100), nullable=False),
        sa.Column('is_ai_generated', sa.Boolean(), nullable=False),
        sa.Column('has_transparent_background', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['owner_user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
        )
    if not _index_exists('stickers', op.f('ix_stickers_id')):
        op.create_index(op.f('ix_stickers_id'), 'stickers', ['id'], unique=False)
    if not _index_exists('stickers', op.f('ix_stickers_owner_user_id')):
        op.create_index(op.f('ix_stickers_owner_user_id'), 'stickers', ['owner_user_id'], unique=False)

    if not _table_exists('designs'):
        op.create_table('designs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('base_image_url', sa.String(length=500), nullable=False),
        sa.Column('preview_image_url', sa.String(length=500), nullable=True),
        sa.Column('is_shared', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
        )
    if not _index_exists('designs', op.f('ix_designs_id')):
        op.create_index(op.f('ix_designs_id'), 'designs', ['id'], unique=False)
    if not _index_exists('designs', op.f('ix_designs_user_id')):
        op.create_index(op.f('ix_designs_user_id'), 'designs', ['user_id'], unique=False)

    if not _table_exists('design_layers'):
        op.create_table('design_layers',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('design_id', sa.Integer(), nullable=False),
        sa.Column('sticker_id', sa.Integer(), nullable=False),
        sa.Column('image_url', sa.String(length=500), nullable=False),
        sa.Column('x', sa.Float(), nullable=False),
        sa.Column('y', sa.Float(), nullable=False),
        sa.Column('scale', sa.Float(), nullable=False),
        sa.Column('rotation', sa.Float(), nullable=False),
        sa.Column('z_index', sa.Integer(), nullable=False),
        sa.Column('tint_color_value', sa.Integer(), nullable=True),
        sa.Column('crop_left', sa.Float(), nullable=False),
        sa.Column('crop_top', sa.Float(), nullable=False),
        sa.Column('crop_right', sa.Float(), nullable=False),
        sa.Column('crop_bottom', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['design_id'], ['designs.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['sticker_id'], ['stickers.id'], ),
        sa.PrimaryKeyConstraint('id')
        )
    if not _index_exists('design_layers', op.f('ix_design_layers_design_id')):
        op.create_index(op.f('ix_design_layers_design_id'), 'design_layers', ['design_id'], unique=False)
    if not _index_exists('design_layers', op.f('ix_design_layers_id')):
        op.create_index(op.f('ix_design_layers_id'), 'design_layers', ['id'], unique=False)

    if not _table_exists('design_shares'):
        op.create_table('design_shares',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('design_id', sa.Integer(), nullable=False),
        sa.Column('share_token', sa.String(length=255), nullable=False),
        sa.Column('public_url', sa.String(length=500), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['design_id'], ['designs.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
        )
    if not _index_exists('design_shares', op.f('ix_design_shares_design_id')):
        op.create_index(op.f('ix_design_shares_design_id'), 'design_shares', ['design_id'], unique=False)
    if not _index_exists('design_shares', op.f('ix_design_shares_id')):
        op.create_index(op.f('ix_design_shares_id'), 'design_shares', ['id'], unique=False)
    if not _index_exists('design_shares', op.f('ix_design_shares_share_token')):
        op.create_index(op.f('ix_design_shares_share_token'), 'design_shares', ['share_token'], unique=True)


def downgrade() -> None:
    """Downgrade schema."""
    if _index_exists('design_shares', op.f('ix_design_shares_share_token')):
        op.drop_index(op.f('ix_design_shares_share_token'), table_name='design_shares')
    if _index_exists('design_shares', op.f('ix_design_shares_id')):
        op.drop_index(op.f('ix_design_shares_id'), table_name='design_shares')
    if _index_exists('design_shares', op.f('ix_design_shares_design_id')):
        op.drop_index(op.f('ix_design_shares_design_id'), table_name='design_shares')
    if _table_exists('design_shares'):
        op.drop_table('design_shares')

    if _index_exists('design_layers', op.f('ix_design_layers_id')):
        op.drop_index(op.f('ix_design_layers_id'), table_name='design_layers')
    if _index_exists('design_layers', op.f('ix_design_layers_design_id')):
        op.drop_index(op.f('ix_design_layers_design_id'), table_name='design_layers')
    if _table_exists('design_layers'):
        op.drop_table('design_layers')

    if _index_exists('designs', op.f('ix_designs_user_id')):
        op.drop_index(op.f('ix_designs_user_id'), table_name='designs')
    if _index_exists('designs', op.f('ix_designs_id')):
        op.drop_index(op.f('ix_designs_id'), table_name='designs')
    if _table_exists('designs'):
        op.drop_table('designs')

    if _index_exists('stickers', op.f('ix_stickers_owner_user_id')):
        op.drop_index(op.f('ix_stickers_owner_user_id'), table_name='stickers')
    if _index_exists('stickers', op.f('ix_stickers_id')):
        op.drop_index(op.f('ix_stickers_id'), table_name='stickers')
    if _table_exists('stickers'):
        op.drop_table('stickers')
