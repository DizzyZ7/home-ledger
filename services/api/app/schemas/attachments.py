from datetime import datetime

from app.schemas.common import APIModel


class ItemAttachmentResponse(APIModel):
    id: str
    item_id: str
    original_filename: str
    content_type: str
    size_bytes: int
    created_at: datetime
    updated_at: datetime
