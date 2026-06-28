from datetime import date, datetime
from typing import Literal

from pydantic import Field

from app.schemas.common import APIModel

DocumentType = Literal["receipt", "warranty", "manual", "other"]


class ItemCreate(APIModel):
    name: str = Field(min_length=1, max_length=120)
    category: str = Field(default="other", min_length=1, max_length=60)
    location: str | None = Field(default=None, max_length=120)
    serial_number: str | None = Field(default=None, max_length=120)
    purchase_date: date | None = None
    warranty_expires_at: date | None = None
    notes: str | None = Field(default=None, max_length=5000)


class ItemUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    category: str | None = Field(default=None, min_length=1, max_length=60)
    location: str | None = Field(default=None, max_length=120)
    serial_number: str | None = Field(default=None, max_length=120)
    purchase_date: date | None = None
    warranty_expires_at: date | None = None
    notes: str | None = Field(default=None, max_length=5000)


class ItemResponse(APIModel):
    id: str
    household_id: str
    name: str
    category: str
    location: str | None
    serial_number: str | None
    purchase_date: date | None
    warranty_expires_at: date | None
    notes: str | None
    created_at: datetime
    updated_at: datetime


class ItemDocumentResponse(APIModel):
    id: str
    household_id: str
    item_id: str
    uploaded_by_id: str
    document_type: DocumentType
    original_filename: str
    content_type: str
    size_bytes: int
    created_at: datetime
    updated_at: datetime


class MaintenanceTaskCreate(APIModel):
    item_id: str
    title: str = Field(min_length=1, max_length=140)
    notes: str | None = Field(default=None, max_length=5000)
    frequency_days: int = Field(ge=1, le=3650)
    next_due_date: date


class MaintenanceTaskUpdate(APIModel):
    title: str | None = Field(default=None, min_length=1, max_length=140)
    notes: str | None = Field(default=None, max_length=5000)
    frequency_days: int | None = Field(default=None, ge=1, le=3650)
    next_due_date: date | None = None


class MaintenanceTaskResponse(APIModel):
    id: str
    household_id: str
    item_id: str
    item_name: str
    title: str
    notes: str | None
    frequency_days: int
    next_due_date: date
    completed_at: datetime | None
    created_at: datetime
    updated_at: datetime


class MaintenanceCompletionResponse(APIModel):
    id: str
    household_id: str
    item_id: str
    item_name: str
    task_id: str
    task_title: str
    completed_at: datetime
    created_at: datetime
    updated_at: datetime
