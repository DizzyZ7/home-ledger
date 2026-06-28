from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.dependencies import CurrentUser, DbSession
from app.api.household_access import active_household_membership, require_active_household_owner
from app.models.household import Household, HouseholdMember
from app.models.item import HomeItem
from app.models.maintenance import MaintenanceCompletion, MaintenanceTask
from app.models.user import User
from app.schemas.exports import (
    HouseholdExportHousehold,
    HouseholdExportItem,
    HouseholdExportResponse,
)
from app.schemas.households import (
    HouseholdDetailResponse,
    HouseholdMemberCreate,
    HouseholdMemberResponse,
    HouseholdSummaryResponse,
)
from app.schemas.items import MaintenanceCompletionResponse, MaintenanceTaskResponse

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


@router.get("/current/export", response_model=HouseholdExportResponse)
def export_current_household(session: DbSession, user: CurrentUser) -> HouseholdExportResponse:
    membership = active_household_membership(session, user.id)
    household = membership.household

    items = list(
        session.scalars(
            select(HomeItem)
            .where(HomeItem.household_id == household.id)
            .order_by(HomeItem.created_at.asc(), HomeItem.id.asc())
        )
    )
    tasks = list(
        session.scalars(
            select(MaintenanceTask)
            .options(selectinload(MaintenanceTask.item))
            .where(MaintenanceTask.household_id == household.id)
            .order_by(MaintenanceTask.created_at.asc(), MaintenanceTask.id.asc())
        )
    )
    completions = list(
        session.scalars(
            select(MaintenanceCompletion)
            .options(selectinload(MaintenanceCompletion.item))
            .where(MaintenanceCompletion.household_id == household.id)
            .order_by(MaintenanceCompletion.completed_at.desc(), MaintenanceCompletion.id.asc())
        )
    )

    return HouseholdExportResponse(
        exported_at=datetime.now(UTC),
        household=HouseholdExportHousehold(
            id=household.id,
            name=household.name,
            created_at=household.created_at,
        ),
        items=[HouseholdExportItem.model_validate(item) for item in items],
        maintenance_tasks=[MaintenanceTaskResponse.model_validate(task) for task in tasks],
        maintenance_completions=[
            MaintenanceCompletionResponse.model_validate(completion) for completion in completions
        ],
    )


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


@router.post("/current/members", response_model=HouseholdMemberResponse, status_code=status.HTTP_201_CREATED)
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
