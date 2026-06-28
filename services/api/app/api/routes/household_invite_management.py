from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select

from app.api.dependencies import CurrentUser, DbSession
from app.api.household_access import require_active_household_owner
from app.api.routes.household_invite_router import router
from app.api.routes.household_invite_support import invite_is_expired, invite_response
from app.core.config import get_settings
from app.models.household_invite import HouseholdInvite
from app.schemas.households import (
    HouseholdInviteCreate,
    HouseholdInviteCreateResponse,
    HouseholdInviteResponse,
)
from app.services.household_invites import create_household_invite_code, household_invite_code_hash


@router.get("/current/invites", response_model=list[HouseholdInviteResponse])
def list_current_household_invites(
    session: DbSession,
    user: CurrentUser,
) -> list[HouseholdInviteResponse]:
    owner_membership = require_active_household_owner(session, user.id)
    query = select(HouseholdInvite)
    query = query.where(HouseholdInvite.household_id == owner_membership.household_id)
    query = query.where(HouseholdInvite.accepted_at.is_(None))
    query = query.where(HouseholdInvite.revoked_at.is_(None))
    query = query.order_by(HouseholdInvite.created_at.desc())
    now = datetime.now(UTC)
    responses = []
    for invite in session.scalars(query):
        if not invite_is_expired(invite.expires_at, now):
            responses.append(invite_response(invite))
    return responses


@router.post(
    "/current/invites",
    response_model=HouseholdInviteCreateResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_current_household_invite(
    payload: HouseholdInviteCreate,
    session: DbSession,
    user: CurrentUser,
) -> HouseholdInviteCreateResponse:
    owner_membership = require_active_household_owner(session, user.id)
    settings = get_settings()
    expires_in_hours = payload.expires_in_hours or settings.household_invite_default_expires_hours
    code = create_household_invite_code()
    code_hash = household_invite_code_hash(code)
    if code_hash is None:
        raise RuntimeError("Generated household invite code was invalid.")

    invite = HouseholdInvite(
        household_id=owner_membership.household_id,
        created_by_user_id=user.id,
        code_hash=code_hash,
        expires_at=datetime.now(UTC) + timedelta(hours=expires_in_hours),
    )
    session.add(invite)
    session.commit()
    session.refresh(invite)
    return HouseholdInviteCreateResponse(
        id=invite.id,
        code=code,
        expires_at=invite.expires_at,
        created_at=invite.created_at,
    )


@router.delete("/current/invites/{invite_id}", status_code=status.HTTP_204_NO_CONTENT)
def revoke_current_household_invite(
    invite_id: str,
    session: DbSession,
    user: CurrentUser,
) -> None:
    owner_membership = require_active_household_owner(session, user.id)
    invite = session.get(HouseholdInvite, invite_id)
    now = datetime.now(UTC)
    if invite is None or invite.household_id != owner_membership.household_id:
        raise HTTPException(
            status_code=404,
            detail={"code": "invite_not_found", "message": "Invitation was not found."},
        )
    if invite.accepted_at is not None or invite.revoked_at is not None or invite_is_expired(invite.expires_at, now):
        raise HTTPException(
            status_code=409,
            detail={"code": "invite_not_active", "message": "Invitation is no longer active."},
        )
    invite.revoked_at = now
    session.commit()
