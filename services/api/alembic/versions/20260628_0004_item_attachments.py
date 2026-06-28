"""add attachment metadata

Revision ID: 20260628_0004
Revises: 20260628_0003
Create Date: 2026-06-28
"""

from alembic import op
import sqlalchemy as sa

revision = "20260628_0004"
down_revision = "20260628_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "item_attachments",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("household_id", sa.String(length=36), nullable=False),
        sa.Column("item_id", sa.String(length=36), nullable=False),
        sa.Column("original_filename", sa.String(length=255), nullable=False),
        sa.Column("storage_key", sa.String(length=32), nullable=False),
        sa.Column("content_type", sa.String(length=120), nullable=False),
        sa.Column("size_bytes", sa.Integer(), nullable=False),
        sa.Column("sha256", sa.String(length=64), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["household_id"], ["households.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["item_id"], ["items.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("storage_key"),
    )
    op.create_index(
        "ix_item_attachments_household_id",
        "item_attachments",
        ["household_id"],
        unique=False,
    )
    op.create_index(
        "ix_item_attachments_item_id",
        "item_attachments",
        ["item_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_item_attachments_item_id", table_name="item_attachments")
    op.drop_index("ix_item_attachments_household_id", table_name="item_attachments")
    op.drop_table("item_attachments")
