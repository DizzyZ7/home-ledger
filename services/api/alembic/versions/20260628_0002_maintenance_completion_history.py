"""add maintenance completion history

Revision ID: 20260628_0002
Revises: 20260627_0001
Create Date: 2026-06-28
"""

from alembic import op
import sqlalchemy as sa

revision = "20260628_0002"
down_revision = "20260627_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "maintenance_completions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("household_id", sa.String(length=36), nullable=False),
        sa.Column("item_id", sa.String(length=36), nullable=False),
        sa.Column("task_id", sa.String(length=36), nullable=False),
        sa.Column("task_title", sa.String(length=140), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["household_id"], ["households.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["item_id"], ["items.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["task_id"], ["maintenance_tasks.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_maintenance_completions_household_id", "maintenance_completions", ["household_id"], unique=False)
    op.create_index("ix_maintenance_completions_item_id", "maintenance_completions", ["item_id"], unique=False)
    op.create_index("ix_maintenance_completions_task_id", "maintenance_completions", ["task_id"], unique=False)
    op.create_index("ix_maintenance_completions_completed_at", "maintenance_completions", ["completed_at"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_maintenance_completions_completed_at", table_name="maintenance_completions")
    op.drop_index("ix_maintenance_completions_task_id", table_name="maintenance_completions")
    op.drop_index("ix_maintenance_completions_item_id", table_name="maintenance_completions")
    op.drop_index("ix_maintenance_completions_household_id", table_name="maintenance_completions")
    op.drop_table("maintenance_completions")
