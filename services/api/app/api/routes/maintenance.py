from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.api.dependencies import CurrentUser, DbSession
from app.api.routes.items import _default_household, _owned_item
from app.models.maintenance import MaintenanceTask
from app.schemas.common import Page
from app.schemas.items import (
    MaintenanceTaskCreate,
    MaintenanceTaskResponse,
    MaintenanceTaskUpdate,
)

router = APIRouter(prefix="/maintenance", tags=["maintenance"])


def _owned_task(session: DbSession, user_id: str, task_id: str) -> MaintenanceTask:
    task = session.scalar(
        select(MaintenanceTask)
        .options(
            selectinload(MaintenanceTask.item),
            selectinload(MaintenanceTask.household),
        )
        .where(MaintenanceTask.id == task_id)
    )
    if task is None or task.household.owner_id != user_id:
        raise HTTPException(
            status_code=404,
            detail={"code": "task_not_found", "message": "Task was not found."},
        )
    return task


@router.get("", response_model=Page[MaintenanceTaskResponse])
def list_tasks(
    session: DbSession,
    user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=30, ge=1, le=100),
    item_id: str | None = Query(default=None, min_length=1, max_length=36),
) -> Page[MaintenanceTaskResponse]:
    household = _default_household(session, user.id)
    filters = [MaintenanceTask.household_id == household.id]
    if item_id is not None:
        filters.append(MaintenanceTask.item_id == item_id)

    statement = select(MaintenanceTask).options(selectinload(MaintenanceTask.item)).where(*filters).order_by(MaintenanceTask.next_due_date.asc()).offset((page - 1) * page_size).limit(page_size)
    total_statement = select(func.count()).select_from(MaintenanceTask).where(*filters)
    tasks = list(session.scalars(statement))
    total = session.scalar(total_statement) or 0
    return Page[MaintenanceTaskResponse](items=tasks, page=page, page_size=page_size, total=total)


@router.post("", response_model=MaintenanceTaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(payload: MaintenanceTaskCreate, session: DbSession, user: CurrentUser) -> MaintenanceTask:
    household = _default_household(session, user.id)
    item = _owned_item(session, user.id, payload.item_id)
    if item.household_id != household.id:
        raise HTTPException(
            status_code=404,
            detail={"code": "item_not_found", "message": "Item was not found."},
        )
    task = MaintenanceTask(household_id=household.id, **payload.model_dump())
    session.add(task)
    session.commit()
    session.refresh(task)
    task.item = item
    return task


@router.patch("/{task_id}", response_model=MaintenanceTaskResponse)
def update_task(
    task_id: str,
    payload: MaintenanceTaskUpdate,
    session: DbSession,
    user: CurrentUser,
) -> MaintenanceTask:
    task = _owned_task(session, user.id, task_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, field, value)
    session.commit()
    session.refresh(task)
    return task


@router.post("/{task_id}/complete", response_model=MaintenanceTaskResponse)
def complete_task(task_id: str, session: DbSession, user: CurrentUser) -> MaintenanceTask:
    task = _owned_task(session, user.id, task_id)
    task.completed_at = datetime.now(UTC)
    task.next_due_date = task.next_due_date + timedelta(days=task.frequency_days)
    session.commit()
    session.refresh(task)
    return task
