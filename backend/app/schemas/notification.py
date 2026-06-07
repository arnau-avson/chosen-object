from datetime import datetime

from pydantic import BaseModel

from ..models.notification import Notification


class NotificationOut(BaseModel):
    id: int
    type: str
    title: str
    body: str | None = None
    is_read: bool
    reference_id: int | None = None
    reference_type: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_model(cls, n: Notification) -> "NotificationOut":
        return cls(
            id=n.id,
            type=n.type,
            title=n.title,
            body=n.body,
            is_read=n.is_read,
            reference_id=n.reference_id,
            reference_type=n.reference_type,
            created_at=n.created_at,
        )
