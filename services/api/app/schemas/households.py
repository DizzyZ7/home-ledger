from datetime import datetime
from typing import Literal

from pydantic import EmailStr, Field, field_validator

from app.schemas.common import APIModel

HouseholdRole = Literal["owner", "member"]


class HouseholdSummaryResponse(APIModel):
    id: str
    name: str
    owner_id: str
    role: HouseholdRole
    is_active: bool
    created_at: datetime


class HouseholdMemberResponse(APIModel):
    user_id: str
    email: EmailStr
    display_name: str
    role: HouseholdRole
    joined_at: datetime


class HouseholdDetailResponse(HouseholdSummaryResponse):
    members: list[HouseholdMemberResponse]


class HouseholdMemberCreate(APIModel):
    email: EmailStr


class HouseholdNamePayload(APIModel):
    name: str = Field(min_length=1, max_length=100)

    @field_validator("name")
    @classmethod
    def normalize_name(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("Household name must not be blank.")
        return normalized


class HouseholdCreate(HouseholdNamePayload):
    pass


class HouseholdUpdate(HouseholdNamePayload):
    pass
