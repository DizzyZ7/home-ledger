"""add household memberships and active household

Revision ID: 20260628_0003
Revises: 20260628_0002
Create Date: 2026-06-28
"""

from alembic import op
import sqlalchemy as sa

revision = "20260628_0003"
down_revision = "20260628_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "household_members",
        sa.Column("household_id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False, server_default="member"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["household_id"], ["households.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("household_id", "user_id"),
    )
    op.create_index("ix_household_members_user_id", "household_members", ["user_id"], unique=False)
    op.add_column("users", sa.Column("active_household_id", sa.String(length=36), nullable=True))
    op.create_foreign_key(
        "fk_users_active_household_id_households",
        "users",
        "households",
        ["active_household_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.execute(
        """
        INSERT INTO household_members (household_id, user_id, role, created_at, updated_at)
        SELECT id, owner_id, 'owner', now(), now()
        FROM households
        ON CONFLICT (household_id, user_id) DO NOTHING
        """
    )
    op.execute(
        """
        UPDATE users
        SET active_household_id = households.id
        FROM households
        WHERE households.owner_id = users.id
          AND users.active_household_id IS NULL
        """
    )


def downgrade() -> None:
    op.drop_constraint("fk_users_active_household_id_households", "users", type_="foreignkey")
    op.drop_column("users", "active_household_id")
    op.drop_index("ix_household_members_user_id", table_name="household_members")
    op.drop_table("household_members")
