from datetime import datetime
from typing import Literal

from pydantic import EmailStr

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
