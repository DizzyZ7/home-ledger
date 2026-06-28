from datetime import date, datetime
from typing import Literal

from app.schemas.common import APIModel
from app.schemas.items import MaintenanceCompletionResponse, MaintenanceTaskResponse


class HouseholdExportHousehold(APIModel):
    id: str
    name: str
    created_at: datetime


class HouseholdExportItem(APIModel):
    id: str
    household_id: str
    name: str
    category: str
    location: str | None
    serial_number: str | None
    purchase_date: date | None
    warranty_expires_at: date | None
    notes: str | None
    archived_at: datetime | None
    created_at: datetime
    updated_at: datetime


class HouseholdExportResponse(APIModel):
    format_version: Literal[1] = 1
    exported_at: datetime
    household: HouseholdExportHousehold
    items: list[HouseholdExportItem]
    maintenance_tasks: list[MaintenanceTaskResponse]
    maintenance_completions: list[MaintenanceCompletionResponse]
