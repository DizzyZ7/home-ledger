from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Literal

from fastapi import APIRouter, File, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import func, select

from app.api.dependencies import CurrentUser, DbSession
from app.api.household_access import active_household_for_user
from app.core.config import get_settings
from app.models.attachment import ItemAttachment
from app.models.item import HomeItem
from app.schemas.attachments import ItemAttachmentResponse
from app.schemas.common import Page
from app.schemas.items import ItemCreate, ItemResponse, ItemUpdate
from app.storage.attachments import AttachmentStorageError, AttachmentTooLargeError, LocalAttachmentStorage

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


def _owned_attachment(item: HomeItem, attachment_id: str, session: DbSession) -> ItemAttachment:
    attachment = session.get(ItemAttachment, attachment_id)
    if attachment is None or attachment.item_id != item.id or attachment.household_id != item.household_id:
        raise HTTPException(
            status_code=404,
            detail={"code": "attachment_not_found", "message": "Attachment was not found."},
        )
    return attachment


def _attachment_storage() -> LocalAttachmentStorage:
    return LocalAttachmentStorage(get_settings().attachment_storage_path)


def _safe_filename(file: UploadFile) -> str:
    filename = Path(file.filename or "").name.strip()
    if not filename or filename in {".", ".."}:
        raise HTTPException(
            status_code=422,
            detail={"code": "attachment_filename_invalid", "message": "A valid filename is required."},
        )
    return filename[:255]


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


@router.get("/{item_id}/attachments", response_model=Page[ItemAttachmentResponse])
def list_item_attachments(
    item_id: str,
    session: DbSession,
    user: CurrentUser,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=30, ge=1, le=100),
) -> Page[ItemAttachmentResponse]:
    item = _owned_item(session, user.id, item_id)
    filters = [ItemAttachment.item_id == item.id, ItemAttachment.household_id == item.household_id]
    statement = (
        select(ItemAttachment)
        .where(*filters)
        .order_by(ItemAttachment.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    count_statement = select(func.count()).select_from(ItemAttachment).where(*filters)
    return Page[ItemAttachmentResponse](
        items=list(session.scalars(statement)),
        page=page,
        page_size=page_size,
        total=session.scalar(count_statement) or 0,
    )


@router.post(
    "/{item_id}/attachments",
    response_model=ItemAttachmentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_item_attachment(
    item_id: str,
    session: DbSession,
    user: CurrentUser,
    file: UploadFile = File(...),
) -> ItemAttachment:
    item = _owned_item(session, user.id, item_id)
    settings = get_settings()
    content_type = (file.content_type or "application/octet-stream").lower()
    if content_type not in settings.parsed_attachment_content_types:
        await file.close()
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail={
                "code": "attachment_content_type_unsupported",
                "message": "Only PDF, JPEG, PNG, and WebP attachments are allowed.",
            },
        )

    filename = _safe_filename(file)
    attachment_count = session.scalar(
        select(func.count()).select_from(ItemAttachment).where(ItemAttachment.item_id == item.id)
    )
    if (attachment_count or 0) >= settings.attachment_max_files_per_item:
        await file.close()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "attachment_limit_reached",
                "message": "The item already has the maximum number of attachments.",
            },
        )

    storage = _attachment_storage()
    try:
        stored = await storage.save(file, max_bytes=settings.attachment_max_bytes)
    except AttachmentTooLargeError:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail={"code": "attachment_too_large", "message": "The attachment exceeds the configured size limit."},
        ) from None
    except OSError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": "attachment_storage_unavailable", "message": "Attachment storage is unavailable."},
        ) from None

    attachment = ItemAttachment(
        household_id=item.household_id,
        item_id=item.id,
        original_filename=filename,
        storage_key=stored.storage_key,
        content_type=content_type,
        size_bytes=stored.size_bytes,
        sha256=stored.sha256,
    )
    session.add(attachment)
    try:
        session.commit()
    except Exception:
        session.rollback()
        storage.delete(stored.storage_key)
        raise
    session.refresh(attachment)
    return attachment


@router.get("/{item_id}/attachments/{attachment_id}/download")
def download_item_attachment(
    item_id: str,
    attachment_id: str,
    session: DbSession,
    user: CurrentUser,
) -> FileResponse:
    item = _owned_item(session, user.id, item_id)
    attachment = _owned_attachment(item, attachment_id, session)
    try:
        attachment_path = _attachment_storage().path_for(attachment.storage_key)
    except AttachmentStorageError:
        attachment_path = None
    if attachment_path is None or not attachment_path.is_file():
        raise HTTPException(
            status_code=404,
            detail={"code": "attachment_file_missing", "message": "Attachment file was not found."},
        )
    return FileResponse(
        path=attachment_path,
        media_type=attachment.content_type,
        filename=attachment.original_filename,
        content_disposition_type="attachment",
    )


@router.delete("/{item_id}/attachments/{attachment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item_attachment(
    item_id: str,
    attachment_id: str,
    session: DbSession,
    user: CurrentUser,
) -> None:
    item = _owned_item(session, user.id, item_id)
    attachment = _owned_attachment(item, attachment_id, session)
    storage_key = attachment.storage_key
    session.delete(attachment)
    session.commit()
    try:
        _attachment_storage().delete(storage_key)
    except (AttachmentStorageError, OSError):
        # The metadata is already gone, so an orphaned private file is harmless and
        # can be removed by a future maintenance command.
        pass


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
