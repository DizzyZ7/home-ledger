"""add household invites

Revision ID: 20260628_0005
Revises: 20260628_0004
Create Date: 2026-06-28
"""

from alembic import op
import sqlalchemy as sa

revision = "20260628_0005"
down_revision = "20260628_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "household_invites",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("household_id", sa.String(length=36), nullable=False),
        sa.Column("created_by_user_id", sa.String(length=36), nullable=False),
        sa.Column("code_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("accepted_by_user_id", sa.String(length=36), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["accepted_by_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code_hash"),
    )
    op.create_index("ix_household_invites_household_id", "household_invites", ["household_id"])
    op.create_index("ix_household_invites_expires_at", "household_invites", ["expires_at"])
    op.create_index("ix_household_invites_accepted_at", "household_invites", ["accepted_at"])
    op.create_index("ix_household_invites_revoked_at", "household_invites", ["revoked_at"])


def downgrade() -> None:
    op.drop_index("ix_household_invites_revoked_at", table_name="household_invites")
    op.drop_index("ix_household_invites_accepted_at", table_name="household_invites")
    op.drop_index("ix_household_invites_expires_at", table_name="household_invites")
    op.drop_index("ix_household_invites_household_id", table_name="household_invites")
    op.drop_table("household_invites")
