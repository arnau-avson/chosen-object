from sqlalchemy.orm import Session

from ..models.notification import Notification


def notify(
    db: Session,
    user_id: int,
    type: str,
    title: str,
    body: str | None = None,
    reference_id: int | None = None,
    reference_type: str | None = None,
) -> Notification:
    """Create a notification for a user."""
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
    return notification
