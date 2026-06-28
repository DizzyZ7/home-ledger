from uuid import uuid4

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin


class Household(TimestampMixin, Base):
    __tablename__ = "households"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    owner = relationship("User", foreign_keys=[owner_id], back_populates="owned_households")
    members = relationship("HouseholdMember", back_populates="household", cascade="all, delete-orphan")
    items = relationship("HomeItem", back_populates="household", cascade="all, delete-orphan")
    maintenance_tasks = relationship(
        "MaintenanceTask",
        back_populates="household",
        cascade="all, delete-orphan",
    )


class HouseholdMember(TimestampMixin, Base):
    __tablename__ = "household_members"

    household_id: Mapped[str] = mapped_column(
        ForeignKey("households.id", ondelete="CASCADE"),
        primary_key=True,
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    role: Mapped[str] = mapped_column(String(16), nullable=False, default="member")

    household = relationship("Household", back_populates="members")
    user = relationship("User", back_populates="household_memberships")
