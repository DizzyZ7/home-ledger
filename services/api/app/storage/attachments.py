from __future__ import annotations

import hashlib
import os
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol
from uuid import uuid4

from fastapi import UploadFile


class AttachmentStorageError(Exception):
    """Base exception for attachment persistence failures."""


class AttachmentTooLargeError(AttachmentStorageError):
    """Raised when an upload exceeds the configured byte limit."""


class AttachmentEmptyError(AttachmentStorageError):
    """Raised when an upload contains no bytes."""


class AttachmentContentMismatchError(AttachmentStorageError):
    """Raised when declared MIME type and file signature do not match."""


@dataclass(frozen=True)
class StoredAttachment:
    storage_key: str
    size_bytes: int
    sha256: str


class AttachmentStorage(Protocol):
    async def save(
        self,
        upload: UploadFile,
        *,
        content_type: str,
        max_bytes: int,
    ) -> StoredAttachment: ...

    def path_for(self, storage_key: str) -> Path: ...

    def delete(self, storage_key: str) -> None: ...


class LocalAttachmentStorage:
    """Stores permitted receipt bytes in a private local directory.

    Database rows retain only an opaque generated storage key. Original filenames
    never participate in the on-disk path, so user input cannot influence where a
    file is written.
    """

    _chunk_size = 64 * 1024

    def __init__(self, base_path: str | Path):
        self._base_path = Path(base_path).expanduser().resolve()

    async def save(
        self,
        upload: UploadFile,
        *,
        content_type: str,
        max_bytes: int,
    ) -> StoredAttachment:
        self._base_path.mkdir(mode=0o700, parents=True, exist_ok=True)
        storage_key = uuid4().hex
        target_path = self.path_for(storage_key)
        temporary_path = self._base_path / f".{storage_key}.uploading"
        digest = hashlib.sha256()
        size_bytes = 0

        try:
            first_chunk = await upload.read(self._chunk_size)
            if not first_chunk:
                raise AttachmentEmptyError
            if not self._matches_signature(content_type, first_chunk):
                raise AttachmentContentMismatchError

            with temporary_path.open("xb") as destination:
                chunk = first_chunk
                while chunk:
                    size_bytes += len(chunk)
                    if size_bytes > max_bytes:
                        raise AttachmentTooLargeError
                    digest.update(chunk)
                    destination.write(chunk)
                    chunk = await upload.read(self._chunk_size)
            os.replace(temporary_path, target_path)
        except Exception:
            temporary_path.unlink(missing_ok=True)
            raise
        finally:
            await upload.close()

        return StoredAttachment(
            storage_key=storage_key,
            size_bytes=size_bytes,
            sha256=digest.hexdigest(),
        )

    def path_for(self, storage_key: str) -> Path:
        if not storage_key.isalnum() or len(storage_key) != 32:
            raise AttachmentStorageError("Invalid attachment storage key.")
        return self._base_path / storage_key

    def delete(self, storage_key: str) -> None:
        self.path_for(storage_key).unlink(missing_ok=True)

    def list_storage_keys(self) -> Iterable[str]:
        """Returns opaque keys for future maintenance or garbage-collection tasks."""
        if not self._base_path.exists():
            return ()
        return (path.name for path in self._base_path.iterdir() if path.is_file())

    @staticmethod
    def _matches_signature(content_type: str, header: bytes) -> bool:
        return (
            (content_type == "application/pdf" and header.startswith(b"%PDF-"))
            or (content_type == "image/jpeg" and header.startswith(b"\xff\xd8\xff"))
            or (content_type == "image/png" and header.startswith(b"\x89PNG\r\n\x1a\n"))
            or (
                content_type == "image/webp"
                and len(header) >= 12
                and header.startswith(b"RIFF")
                and header[8:12] == b"WEBP"
            )
        )
