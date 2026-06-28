from typing import Literal

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import select

from app.api.dependencies import CurrentUser, DbSession
from app.api.document_storage import DocumentStorage
from app.api.routes.items import _owned_item
from app.models.document import ItemDocument
from app.schemas.items import ItemDocumentResponse
from app.services.document_storage import DocumentUploadError

router = APIRouter(prefix="/items/{item_id}/documents", tags=["documents"])
DocumentType = Literal["receipt", "warranty", "manual", "other"]


def _active_item(session: DbSession, user_id: str, item_id: str):
    item = _owned_item(session, user_id, item_id)
    if item.archived_at is not None:
        raise HTTPException(
            status_code=409,
            detail={
                "code": "item_archived",
                "message": "Restore the item before attaching documents.",
            },
        )
    return item


def _owned_document(session: DbSession, user_id: str, item_id: str, document_id: str) -> ItemDocument:
    item = _owned_item(session, user_id, item_id)
    document = session.get(ItemDocument, document_id)
    if document is None or document.item_id != item.id or document.household_id != item.household_id:
        raise HTTPException(
            status_code=404,
            detail={"code": "document_not_found", "message": "Document was not found."},
        )
    return document


@router.get("", response_model=list[ItemDocumentResponse])
def list_documents(item_id: str, session: DbSession, user: CurrentUser) -> list[ItemDocument]:
    item = _owned_item(session, user.id, item_id)
    return list(
        session.scalars(
            select(ItemDocument)
            .where(
                ItemDocument.item_id == item.id,
                ItemDocument.household_id == item.household_id,
            )
            .order_by(ItemDocument.created_at.desc())
        )
    )


@router.post("", response_model=ItemDocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    item_id: str,
    session: DbSession,
    user: CurrentUser,
    storage: DocumentStorage,
    file: UploadFile = File(...),
    document_type: DocumentType = Form(default="receipt"),
) -> ItemDocument:
    item = _active_item(session, user.id, item_id)
    original_filename = (file.filename or "document").strip()
    if not original_filename or len(original_filename) > 255:
        raise HTTPException(
            status_code=422,
            detail={"code": "invalid_filename", "message": "Document filename is invalid."},
        )

    try:
        stored = await storage.save(file)
    except DocumentUploadError as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "invalid_document", "message": str(exc)},
        ) from exc

    document = ItemDocument(
        household_id=item.household_id,
        item_id=item.id,
        uploaded_by_id=user.id,
        document_type=document_type,
        original_filename=original_filename,
        storage_key=stored.storage_key,
        content_type=file.content_type or "application/octet-stream",
        size_bytes=stored.size_bytes,
    )
    session.add(document)
    try:
        session.commit()
    except Exception:
        session.rollback()
        storage.delete(stored.storage_key)
        raise
    session.refresh(document)
    return document


@router.get("/{document_id}/download")
def download_document(
    item_id: str,
    document_id: str,
    session: DbSession,
    user: CurrentUser,
    storage: DocumentStorage,
) -> FileResponse:
    document = _owned_document(session, user.id, item_id, document_id)
    try:
        path = storage.path_for(document.storage_key)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=404,
            detail={"code": "document_content_missing", "message": "Document content was not found."},
        ) from exc
    return FileResponse(
        path,
        media_type=document.content_type,
        filename=document.original_filename,
        content_disposition_type="attachment",
    )


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    item_id: str,
    document_id: str,
    session: DbSession,
    user: CurrentUser,
    storage: DocumentStorage,
) -> None:
    document = _owned_document(session, user.id, item_id, document_id)
    storage_key = document.storage_key
    session.delete(document)
    session.commit()
    storage.delete(storage_key)
