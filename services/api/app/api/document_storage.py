from pathlib import Path
from typing import Annotated

from fastapi import Depends

from app.core.config import get_settings
from app.services.document_storage import LocalDocumentStorage


def get_document_storage() -> LocalDocumentStorage:
    settings = get_settings()
    return LocalDocumentStorage(
        Path(settings.document_storage_path),
        max_upload_bytes=settings.document_max_upload_bytes,
    )


DocumentStorage = Annotated[LocalDocumentStorage, Depends(get_document_storage)]
