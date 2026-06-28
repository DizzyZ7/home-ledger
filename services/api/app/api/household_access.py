from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.dependencies import DbSession
from app.models.household import Household, HouseholdMember
from app.models.user import User


def active_household_membership(session: DbSession, user_id: str) -> HouseholdMember:
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail={"code": "invalid_user", "message": "User is not available."})

    if user.active_household_id is not None:
        membership = session.scalar(
            select(HouseholdMember)
            .options(selectinload(HouseholdMember.household))
            .where(
                HouseholdMember.user_id == user.id,
                HouseholdMember.household_id == user.active_household_id,
            )
        )
        if membership is not None:
            return membership

    membership = session.scalar(
        select(HouseholdMember)
        .options(selectinload(HouseholdMember.household))
        .where(HouseholdMember.user_id == user.id)
        .join(HouseholdMember.household)
        .order_by(Household.created_at.asc())
    )
    if membership is None:
        raise HTTPException(
            status_code=409,
            detail={"code": "household_missing", "message": "Household is missing."},
        )
    return membership


def active_household_for_user(session: DbSession, user_id: str) -> Household:
    return active_household_membership(session, user_id).household


def require_active_household_owner(session: DbSession, user_id: str) -> HouseholdMember:
    membership = active_household_membership(session, user_id)
    if membership.role != "owner":
        raise HTTPException(
            status_code=403,
            detail={
                "code": "household_owner_required",
                "message": "Only the household owner can manage members.",
            },
        )
    return membership
