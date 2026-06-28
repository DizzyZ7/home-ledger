from datetime import UTC, datetime

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.dependencies import CurrentUser, DbSession
from app.api.routes.household_core import summary_response
from app.api.routes.household_invite_router import router
from app.api.routes.household_invite_support import invite_is_expired
from app.models.household import HouseholdMember
from app.models.household_invite import HouseholdInvite
from app.schemas.households import HouseholdInviteAccept, HouseholdSummaryResponse
from app.services.household_invites import household_invite_code_hash


@router.post("/invites/accept", response_model=HouseholdSummaryResponse)
def accept_household_invite(
    payload: HouseholdInviteAccept,
    session: DbSession,
    user: CurrentUser,
) -> HouseholdSummaryResponse:
    code_hash = household_invite_code_hash(payload.code)
    if code_hash is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "invite_invalid", "message": "Invitation is invalid or expired."},
        )

    query = select(HouseholdInvite).options(selectinload(HouseholdInvite.household))
    query = query.where(HouseholdInvite.code_hash == code_hash)
    query = query.with_for_update()
    invite = session.scalar(query)
    now = datetime.now(UTC)
    if invite is None or invite.accepted_at is not None or invite.revoked_at is not None or invite_is_expired(invite.expires_at, now):
        raise HTTPException(
            status_code=404,
            detail={"code": "invite_invalid", "message": "Invitation is invalid or expired."},
        )

    existing = session.get(
        HouseholdMember,
        {"household_id": invite.household_id, "user_id": user.id},
    )
    if existing is not None:
        raise HTTPException(
            status_code=409,
            detail={"code": "member_exists", "message": "You are already a household member."},
        )

    membership = HouseholdMember(
        household_id=invite.household_id,
        user_id=user.id,
        role="member",
    )
    session.add(membership)
    invite.accepted_at = now
    invite.accepted_by_user_id = user.id
    user.active_household_id = invite.household_id
    session.commit()
    session.refresh(membership)
    return summary_response(membership, user.active_household_id)
