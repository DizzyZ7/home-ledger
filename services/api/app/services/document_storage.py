from dataclasses import dataclass
from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile


class DocumentUploadError(ValueError):
    pass


@dataclass(frozen=True)
class StoredDocument:
    storage_key: str
    size_bytes: int


class LocalDocumentStorage:
    _extensions = {
        "application/pdf": ".pdf",
        "image/jpeg": ".jpg",
        "image/png": ".png",
    }
    _signatures = {
        "application/pdf": b"%PDF-",
        "image/jpeg": b"\xff\xd8\xff",
        "image/png": b"\x89PNG\r\n\x1a\n",
    }

    def __init__(self, root: Path, *, max_upload_bytes: int) -> None:
        self._root = root.resolve()
        self._max_upload_bytes = max_upload_bytes

    async def save(self, upload: UploadFile) -> StoredDocument:
        content_type = upload.content_type or ""
        extension = self._extensions.get(content_type)
        if extension is None:
            raise DocumentUploadError("Only PDF, JPEG, and PNG documents are supported.")

        self._root.mkdir(parents=True, exist_ok=True)
        storage_key = f"{uuid4().hex}{extension}"
        target = self._path_for(storage_key)
        total_size = 0
        prefix = b""

        try:
            with target.open("xb") as destination:
                while chunk := await upload.read(1024 * 1024):
                    total_size += len(chunk)
                    if total_size > self._max_upload_bytes:
                        raise DocumentUploadError("Document exceeds the configured upload size limit.")
                    if len(prefix) < len(self._signatures[content_type]):
                        prefix += chunk[: len(self._signatures[content_type]) - len(prefix)]
                    destination.write(chunk)

            if total_size == 0:
                raise DocumentUploadError("Document cannot be empty.")
            if not prefix.startswith(self._signatures[content_type]):
                raise DocumentUploadError("Document signature does not match its content type.")
            return StoredDocument(storage_key=storage_key, size_bytes=total_size)
        except Exception:
            target.unlink(missing_ok=True)
            raise
        finally:
            await upload.close()

    def path_for(self, storage_key: str) -> Path:
        target = self._path_for(storage_key)
        if not target.is_file():
            raise FileNotFoundError(storage_key)
        return target

    def delete(self, storage_key: str) -> None:
        self._path_for(storage_key).unlink(missing_ok=True)

    def _path_for(self, storage_key: str) -> Path:
        if Path(storage_key).name != storage_key:
            raise ValueError("Invalid storage key.")
        target = (self._root / storage_key).resolve()
        if not target.is_relative_to(self._root):
            raise ValueError("Invalid storage key.")
        return target
