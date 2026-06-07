from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.notification_repository import NotificationRepository
from ..schemas.notification import NotificationOut


class NotificationService:
    def __init__(self, db: Session) -> None:
        self.repo = NotificationRepository(db)

    def list_notifications(
        self, user: User, offset: int = 0, limit: int = 20
    ) -> list[NotificationOut]:
        notifications = self.repo.get_notifications(user.id, offset, limit)
        return [NotificationOut.from_model(n) for n in notifications]

    def mark_read(self, user: User, notification_id: int) -> NotificationOut:
        notification = self.repo.get_by_id(notification_id, user.id)
        if notification is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found.",
            )
        notification = self.repo.mark_read(notification)
        return NotificationOut.from_model(notification)

    def mark_all_read(self, user: User) -> dict:
        self.repo.mark_all_read(user.id)
        return {"read_all": True}

    def get_unread_count(self, user: User) -> dict:
        count = self.repo.get_unread_count(user.id)
        return {"unread_count": count}
