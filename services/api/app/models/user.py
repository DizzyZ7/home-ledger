from uuid import uuid4

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(80), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    active_household_id: Mapped[str | None] = mapped_column(
        ForeignKey("households.id", ondelete="SET NULL"),
        nullable=True,
    )

    owned_households = relationship(
        "Household",
        foreign_keys="Household.owner_id",
        back_populates="owner",
        cascade="all, delete-orphan",
    )
    household_memberships = relationship(
        "HouseholdMember",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    active_household = relationship("Household", foreign_keys=[active_household_id], post_update=True)
