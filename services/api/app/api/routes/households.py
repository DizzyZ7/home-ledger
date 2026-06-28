from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.dependencies import CurrentUser, DbSession
from app.api.household_access import active_household_membership, require_active_household_owner
from app.core.config import get_settings
from app.models.household import Household, HouseholdMember
from app.models.household_invite import HouseholdInvite
from app.models.user import User
from app.schemas.households import (
    HouseholdCreate,
    HouseholdDetailResponse,
    HouseholdInviteAccept,
    HouseholdInviteCreate,
    HouseholdInviteCreateResponse,
    HouseholdInviteResponse,
    HouseholdMemberCreate,
    HouseholdMemberResponse,
    HouseholdSummaryResponse,
    HouseholdUpdate,
)
from app.services.household_invites import create_household_invite_code, household_invite_code_hash

router = APIRouter(prefix="/households", tags=["households"])


def _summary_response(membership: HouseholdMember, active_household_id: str | None) -> HouseholdSummaryResponse:
    household = membership.household
    return HouseholdSummaryResponse(
        id=household.id,
        name=household.name,
        owner_id=household.owner_id,
        role=membership.role,
        is_active=household.id == active_household_id,
        created_at=household.created_at,
    )


def _member_response(membership: HouseholdMember) -> HouseholdMemberResponse:
    member_user = membership.user
    return HouseholdMemberResponse(
        user_id=member_user.id,
        email=member_user.email,
        display_name=member_user.display_name,
        role=membership.role,
        joined_at=membership.created_at,
    )


def _invite_response(invite: HouseholdInvite) -> HouseholdInviteResponse:
    return HouseholdInviteResponse(
        id=invite.id,
        expires_at=invite.expires_at,
        created_at=invite.created_at,
    )


def _invite_is_expired(expires_at: datetime, now: datetime) -> bool:
    normalized_expiry = expires_at if expires_at.tzinfo is not None else expires_at.replace(tzinfo=UTC)
    return normalized_expiry <= now


@router.get("", response_model=list[HouseholdSummaryResponse])
def list_households(session: DbSession, user: CurrentUser) -> list[HouseholdSummaryResponse]:
    memberships = list(
        session.scalars(
            select(HouseholdMember)
            .options(selectinload(HouseholdMember.household))
            .join(HouseholdMember.household)
            .where(HouseholdMember.user_id == user.id)
            .order_by(Household.created_at.asc())
        )
    )
    return [_summary_response(membership, user.active_household_id) for membership in memberships]


@router.post("", response_model=HouseholdSummaryResponse, status_code=status.HTTP_201_CREATED)
def create_household(
    payload: HouseholdCreate,
    session: DbSession,
    user: CurrentUser,
) -> HouseholdSummaryResponse:
    household = Household(name=payload.name, owner_id=user.id)
    session.add(household)
    session.flush()

    membership = HouseholdMember(
        household_id=household.id,
        user_id=user.id,
        role="owner",
    )
    session.add(membership)
    user.active_household_id = household.id
    session.commit()
    session.refresh(household)

    return HouseholdSummaryResponse(
        id=household.id,
        name=household.name,
        owner_id=household.owner_id,
        role="owner",
        is_active=True,
        created_at=household.created_at,
    )


@router.get("/current", response_model=HouseholdDetailResponse)
def get_current_household(session: DbSession, user: CurrentUser) -> HouseholdDetailResponse:
    membership = active_household_membership(session, user.id)
    members = list(
        session.scalars(
            select(HouseholdMember)
            .options(selectinload(HouseholdMember.user))
            .where(HouseholdMember.household_id == membership.household_id)
            .order_by(HouseholdMember.created_at.asc())
        )
    )
    return HouseholdDetailResponse(
        **_summary_response(membership, user.active_household_id).model_dump(),
        members=[_member_response(member) for member in members],
    )


@router.patch("/current", response_model=HouseholdSummaryResponse)
def rename_current_household(
    payload: HouseholdUpdate,
    session: DbSession,
    user: CurrentUser,
) -> HouseholdSummaryResponse:
    owner_membership = require_active_household_owner(session, user.id)
    household = owner_membership.household
    household.name = payload.name
    session.commit()
    session.refresh(household)
    return _summary_response(owner_membership, user.active_household_id)


@router.get("/current/invites", response_model=list[HouseholdInviteResponse])
def list_current_household_invites(
    session: DbSession,
    user: CurrentUser,
) -> list[HouseholdInviteResponse]:
    owner_membership = require_active_household_owner(session, user.id)
    now = datetime.now(UTC)
    invites = list(
        session.scalars(
            select(HouseholdInvite)
            .where(
                HouseholdInvite.household_id == owner_membership.household_id,
                HouseholdInvite.accepted_at.is_(None),
                HouseholdInvite.revoked_at.is_(None),
                HouseholdInvite.expires_at > now,
            )
            .order_by(HouseholdInvite.created_at.desc())
        )
    )
    return [_invite_response(invite) for invite in invites]


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
    if invite.accepted_at is not None or invite.revoked_at is not None or _invite_is_expired(invite.expires_at, now):
        raise HTTPException(
            status_code=409,
            detail={"code": "invite_not_active", "message": "Invitation is no longer active."},
        )
    invite.revoked_at = now
    session.commit()


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

    invite = session.scalar(
        select(HouseholdInvite)
        .options(selectinload(HouseholdInvite.household))
        .where(HouseholdInvite.code_hash == code_hash)
        .with_for_update()
    )
    now = datetime.now(UTC)
    if (
        invite is None
        or invite.accepted_at is not None
        or invite.revoked_at is not None
        or _invite_is_expired(invite.expires_at, now)
    ):
        raise HTTPException(
            status_code=404,
            detail={"code": "invite_invalid", "message": "Invitation is invalid or expired."},
        )

    existing_membership = session.get(
        HouseholdMember,
        {"household_id": invite.household_id, "user_id": user.id},
    )
    if existing_membership is not None:
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
    return _summary_response(membership, user.active_household_id)


@router.post("/{household_id}/select", response_model=HouseholdSummaryResponse)
def select_household(household_id: str, session: DbSession, user: CurrentUser) -> HouseholdSummaryResponse:
    membership = session.scalar(
        select(HouseholdMember)
        .options(selectinload(HouseholdMember.household))
        .where(
            HouseholdMember.household_id == household_id,
            HouseholdMember.user_id == user.id,
        )
    )
    if membership is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "household_not_found", "message": "Household was not found."},
        )

    user.active_household_id = household_id
    session.commit()
    session.refresh(user)
    return _summary_response(membership, user.active_household_id)


@router.post(
    "/current/members",
    response_model=HouseholdMemberResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_household_member(
    payload: HouseholdMemberCreate,
    session: DbSession,
    user: CurrentUser,
) -> HouseholdMemberResponse:
    owner_membership = require_active_household_owner(session, user.id)
    invited_user = session.scalar(select(User).where(User.email == str(payload.email).lower()))
    if invited_user is None:
        raise HTTPException(
            status_code=404,
            detail={
                "code": "user_not_found",
                "message": "Ask this person to create a HomeLedger account before adding them.",
            },
        )
    if invited_user.id == user.id:
        raise HTTPException(
            status_code=409,
            detail={"code": "owner_already_member", "message": "The household owner is already a member."},
        )

    existing = session.get(
        HouseholdMember,
        {
            "household_id": owner_membership.household_id,
            "user_id": invited_user.id,
        },
    )
    if existing is not None:
        raise HTTPException(
            status_code=409,
            detail={"code": "member_exists", "message": "This user is already a household member."},
        )

    membership = HouseholdMember(
        household_id=owner_membership.household_id,
        user_id=invited_user.id,
        role="member",
    )
    session.add(membership)
    session.commit()
    session.refresh(membership)
    membership.user = invited_user
    return _member_response(membership)


@router.delete("/current/members/{member_user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_household_member(member_user_id: str, session: DbSession, user: CurrentUser) -> None:
    owner_membership = require_active_household_owner(session, user.id)
    if member_user_id == user.id:
        raise HTTPException(
            status_code=409,
            detail={"code": "owner_cannot_be_removed", "message": "The household owner cannot be removed."},
        )

    membership = session.get(
        HouseholdMember,
        {
            "household_id": owner_membership.household_id,
            "user_id": member_user_id,
        },
    )
    if membership is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "member_not_found", "message": "Household member was not found."},
        )
    if membership.role == "owner":
        raise HTTPException(
            status_code=409,
            detail={"code": "owner_cannot_be_removed", "message": "The household owner cannot be removed."},
        )

    member_user = session.get(User, member_user_id)
    fallback = session.scalar(
        select(HouseholdMember)
        .where(
            HouseholdMember.user_id == member_user_id,
            HouseholdMember.household_id != owner_membership.household_id,
        )
        .join(HouseholdMember.household)
        .order_by(Household.created_at.asc())
    )
    if member_user is not None and member_user.active_household_id == owner_membership.household_id:
        member_user.active_household_id = fallback.household_id if fallback is not None else None

    session.delete(membership)
    session.commit()
