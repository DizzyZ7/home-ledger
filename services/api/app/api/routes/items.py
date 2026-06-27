from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select

from app.api.dependencies import CurrentUser, DbSession
from app.models.household import Household
from app.models.item import HomeItem
from app.schemas.common import Page
from app.schemas.items import ItemCreate, ItemResponse, ItemUpdate

router = APIRouter(prefix="/items", tags=["items"])


def _default_household(session: DbSession, user_id: str) -> Household:
    household = session.scalar(select(Household).where(Household.owner_id == user_id).order_by(Household.created_at))
    if household is None:
        raise HTTPException(status_code=409, detail={"code": "household_missing", "message": "Household is missing."})
    return household


def _owned_item(session: DbSession, user_id: str, item_id: str) -> HomeItem:
    item = session.get(HomeItem, item_id)
    if item is None or item.household.owner_id != user_id:
        raise HTTPException(status_code=404, detail={"code": "item_not_found", "message": "Item was not found."})
    return item


@router.get("", response_model=Page[ItemResponse])
def list_items(
    session: DbSession,
    user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=30, ge=1, le=100),
    query: str | None = Query(default=None, min_length=1, max_length=120),
) -> Page[ItemResponse]:
    household = _default_household(session, user.id)
    statement = select(HomeItem).where(
        HomeItem.household_id == household.id,
        HomeItem.archived_at.is_(None),
    )
    count_statement = select(func.count()).select_from(HomeItem).where(
        HomeItem.household_id == household.id,
        HomeItem.archived_at.is_(None),
    )
    if query:
        pattern = f"%{query.strip()}%"
        statement = statement.where(HomeItem.name.ilike(pattern))
        count_statement = count_statement.where(HomeItem.name.ilike(pattern))

    statement = statement.order_by(HomeItem.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    return Page[ItemResponse](
        items=list(session.scalars(statement)),
        page=page,
        page_size=page_size,
        total=session.scalar(count_statement) or 0,
    )


@router.post("", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
def create_item(payload: ItemCreate, session: DbSession, user: CurrentUser) -> HomeItem:
    household = _default_household(session, user.id)
    item = HomeItem(household_id=household.id, **payload.model_dump())
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@router.get("/{item_id}", response_model=ItemResponse)
def get_item(item_id: str, session: DbSession, user: CurrentUser) -> HomeItem:
    return _owned_item(session, user.id, item_id)


@router.patch("/{item_id}", response_model=ItemResponse)
def update_item(item_id: str, payload: ItemUpdate, session: DbSession, user: CurrentUser) -> HomeItem:
    item = _owned_item(session, user.id, item_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    session.commit()
    session.refresh(item)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def archive_item(item_id: str, session: DbSession, user: CurrentUser) -> None:
    item = _owned_item(session, user.id, item_id)
    item.archived_at = datetime.now(UTC)
    session.commit()
