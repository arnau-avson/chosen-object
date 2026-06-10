from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories.device_token_repository import DeviceTokenRepository

router = APIRouter(prefix="/device-tokens", tags=["device-tokens"])


class RegisterTokenIn(BaseModel):
    fcm_token: str
    platform: str


@router.post("", summary="Register or update FCM device token")
def register_token(
    data: RegisterTokenIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    DeviceTokenRepository(db).upsert(
        user_id=current_user.id,
        fcm_token=data.fcm_token,
        platform=data.platform,
    )
    return {"registered": True}


@router.delete("/{fcm_token}", summary="Remove FCM device token on logout")
def delete_token(
    fcm_token: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    DeviceTokenRepository(db).delete_token(fcm_token)
    return {"deleted": True}
