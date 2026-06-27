from uuid import uuid4

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin


class Household(TimestampMixin, Base):
    __tablename__ = "households"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4))
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    owner: Mapped["User"] = relationship(back_populates="households")
    items: Mapped[list["HomeItem"]] = relationship(
        back_populates="household", cascade="all, delete-orphan"
    )
    maintenance_tasks: Mapped[list["MaintenanceTask"]] = relationship(
        back_populates="household", cascade="all, delete-orphan"
    )
