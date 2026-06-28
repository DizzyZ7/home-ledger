from datetime import UTC, date, datetime, timedelta
from typing import Literal

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select

from app.api.dependencies import CurrentUser, DbSession
from app.api.household_access import active_household_for_user
from app.models.item import HomeItem
from app.schemas.common import Page
from app.schemas.items import ItemCreate, ItemResponse, ItemUpdate

router = APIRouter(prefix="/items", tags=["items"])
WarrantyState = Literal["expired", "expiring", "valid", "none"]


def _default_household(session: DbSession, user_id: str):
    return active_household_for_user(session, user_id)


def _owned_item(session: DbSession, user_id: str, item_id: str) -> HomeItem:
    household = _default_household(session, user_id)
    item = session.get(HomeItem, item_id)
    if item is None or item.household_id != household.id:
        raise HTTPException(status_code=404, detail={"code": "item_not_found", "message": "Item was not found."})
    return item


@router.get("", response_model=Page[ItemResponse])
def list_items(
    session: DbSession,
    user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=30, ge=1, le=100),
    query: str | None = Query(default=None, min_length=1, max_length=120),
    archived: bool = Query(default=False),
    warranty_state: WarrantyState | None = None,
    warranty_window_days: int = Query(default=45, ge=1, le=3650),
) -> Page[ItemResponse]:
    household = _default_household(session, user.id)
    archive_filter = HomeItem.archived_at.is_not(None) if archived else HomeItem.archived_at.is_(None)
    filters = [HomeItem.household_id == household.id, archive_filter]

    if query:
        filters.append(HomeItem.name.ilike(f"%{query.strip()}%"))

    if warranty_state is not None:
        today = date.today()
        window_end = today + timedelta(days=warranty_window_days)
        if warranty_state == "expired":
            filters.append(HomeItem.warranty_expires_at < today)
        elif warranty_state == "expiring":
            filters.extend(
                [
                    HomeItem.warranty_expires_at >= today,
                    HomeItem.warranty_expires_at <= window_end,
                ]
            )
        elif warranty_state == "valid":
            filters.append(HomeItem.warranty_expires_at > window_end)
        else:
            filters.append(HomeItem.warranty_expires_at.is_(None))

    order_by = HomeItem.warranty_expires_at.asc() if warranty_state is not None and warranty_state != "none" else HomeItem.created_at.desc()
    statement = select(HomeItem).where(*filters).order_by(order_by).offset((page - 1) * page_size).limit(page_size)
    count_statement = select(func.count()).select_from(HomeItem).where(*filters)
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


@router.post("/{item_id}/restore", response_model=ItemResponse)
def restore_item(item_id: str, session: DbSession, user: CurrentUser) -> HomeItem:
    item = _owned_item(session, user.id, item_id)
    item.archived_at = None
    session.commit()
    session.refresh(item)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def archive_item(item_id: str, session: DbSession, user: CurrentUser) -> None:
    item = _owned_item(session, user.id, item_id)
    item.archived_at = datetime.now(UTC)
    session.commit()
