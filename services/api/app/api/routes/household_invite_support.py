from datetime import UTC, datetime

from app.models.household_invite import HouseholdInvite
from app.schemas.households import HouseholdInviteResponse


def invite_is_expired(expires_at: datetime, now: datetime) -> bool:
    expiry = expires_at if expires_at.tzinfo is not None else expires_at.replace(tzinfo=UTC)
    return expiry <= now


def invite_response(invite: HouseholdInvite) -> HouseholdInviteResponse:
    return HouseholdInviteResponse(
        id=invite.id,
        expires_at=invite.expires_at,
        created_at=invite.created_at,
    )
