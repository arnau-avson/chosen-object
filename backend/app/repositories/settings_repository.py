from sqlalchemy.orm import Session

from ..models.settings import UserSettings


class SettingsRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_user(self, user_id: int) -> UserSettings | None:
        return (
            self.db.query(UserSettings)
            .filter(UserSettings.user_id == user_id)
            .first()
        )

    def create(self, user_id: int) -> UserSettings:
        settings = UserSettings(user_id=user_id)
        self.db.add(settings)
        self.db.commit()
        self.db.refresh(settings)
        return settings

    def update(self, settings: UserSettings, data: dict) -> UserSettings:
        for key, value in data.items():
            setattr(settings, key, value)
        self.db.commit()
        self.db.refresh(settings)
        return settings
