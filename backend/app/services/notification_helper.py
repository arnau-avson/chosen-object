from sqlalchemy.orm import Session

from ..models.notification import Notification
from ..services.push_service import send_push_notification


def notify(
    db: Session,
    user_id: int,
    type: str,
    title: str,
    body: str | None = None,
    reference_id: int | None = None,
    reference_type: str | None = None,
) -> Notification:
    """Create a notification for a user and send a push notification."""
    notification = Notification(
        user_id=user_id,
        type=type,
        title=title,
        body=body,
        reference_id=reference_id,
        reference_type=reference_type,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)

    send_push_notification(
        db=db,
        user_id=user_id,
        title=title,
        body=body or "",
        data={
            "type": type,
            "notification_id": notification.id,
            "reference_id": reference_id or "",
            "reference_type": reference_type or "",
        },
    )

    return notification
