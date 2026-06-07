from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.settings import SettingsOut, SettingsUpdate
from app.services.settings_service import SettingsService

router = APIRouter(prefix="/settings", tags=["settings"])


@router.get(
    "",
    response_model=SettingsOut,
    summary="Get user settings",
)
def get_settings(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> SettingsOut:
    return SettingsService(db).get_settings(current_user)


@router.patch(
    "",
    response_model=SettingsOut,
    summary="Update user settings",
)
def update_settings(
    data: SettingsUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> SettingsOut:
    return SettingsService(db).update_settings(current_user, data)
