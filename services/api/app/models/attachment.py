from uuid import uuid4

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin


class ItemAttachment(TimestampMixin, Base):
    __tablename__ = "item_attachments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    household_id: Mapped[str] = mapped_column(
        ForeignKey("households.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    item_id: Mapped[str] = mapped_column(
        ForeignKey("items.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    original_filename: Mapped[str] = mapped_column(String(255), nullable=False)
    storage_key: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    content_type: Mapped[str] = mapped_column(String(120), nullable=False)
    size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    sha256: Mapped[str] = mapped_column(String(64), nullable=False)

    item = relationship("HomeItem", back_populates="attachments")
    household = relationship("Household")
