from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.settings_repository import SettingsRepository
from ..schemas.settings import SettingsOut, SettingsUpdate


class SettingsService:
    def __init__(self, db: Session) -> None:
        self.repo = SettingsRepository(db)

    def get_settings(self, user: User) -> SettingsOut:
        settings = self.repo.get_by_user(user.id)
        if settings is None:
            return SettingsOut.defaults()
        return SettingsOut.from_model(settings)

    def update_settings(self, user: User, data: SettingsUpdate) -> SettingsOut:
        settings = self.repo.get_by_user(user.id)
        if settings is None:
            settings = self.repo.create(user.id)

        updates = data.model_dump(exclude_none=True)
        if updates:
            settings = self.repo.update(settings, updates)

        return SettingsOut.from_model(settings)
