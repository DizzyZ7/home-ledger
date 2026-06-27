from datetime import date, datetime
from uuid import uuid4

from sqlalchemy import Date, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin


class HomeItem(TimestampMixin, Base):
    __tablename__ = "items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4))
    household_id: Mapped[str] = mapped_column(
        ForeignKey("households.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    category: Mapped[str] = mapped_column(String(60), default="other", nullable=False)
    location: Mapped[str | None] = mapped_column(String(120))
    serial_number: Mapped[str | None] = mapped_column(String(120))
    purchase_date: Mapped[date | None] = mapped_column(Date)
    warranty_expires_at: Mapped[date | None] = mapped_column(Date)
    notes: Mapped[str | None] = mapped_column(Text)
    archived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), index=True)

    household = relationship("Household", back_populates="items")
    maintenance_tasks = relationship(
        "MaintenanceTask",
        back_populates="item",
        cascade="all, delete-orphan",
    )
