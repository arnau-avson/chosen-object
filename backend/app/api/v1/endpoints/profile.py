from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.profile import ProfileOut, ProfileUpdate
from app.services.profile_service import ProfileService

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get(
    "/me",
    response_model=ProfileOut,
    summary="Get authenticated user profile",
)
def get_profile(
    current_user: Annotated[User, Depends(get_current_user)],
) -> ProfileOut:
    return ProfileOut.from_user(current_user)


@router.put(
    "/me",
    response_model=ProfileOut,
    summary="Update profile text fields",
)
def update_profile(
    data: ProfileUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> ProfileOut:
    return ProfileService(db).update_profile(current_user, data)


@router.get(
    "/check-username/{username}",
    summary="Check if a username is available",
)
def check_username(
    username: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    name = username.strip().lower()
    if len(name) < 6:
        return {"available": False, "reason": "Must be at least 6 characters."}
    existing = UserRepository(db).get_by_username(name)
    if existing and existing.id != current_user.id:
        return {"available": False, "reason": "This username is already taken."}
    return {"available": True}


@router.post(
    "/me/avatar",
    response_model=ProfileOut,
    summary="Update avatar (colour or image)",
)
async def update_avatar(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    type: str = Form(..., description="'color' or 'image'"),
    color: str | None = Form(None, description="Hex colour e.g. #2E2520"),
    file: UploadFile | None = File(None, description="Image file (required if type=image)"),
) -> ProfileOut:
    return await ProfileService(db).upload_avatar(
        current_user,
        avatar_type=type,
        color=color,
        file=file,
    )


@router.post(
    "/me/banner",
    response_model=ProfileOut,
    summary="Update banner (colour or image)",
)
async def update_banner(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    type: str = Form(..., description="'color' or 'image'"),
    color: str | None = Form(None, description="Hex colour e.g. #4A3F35"),
    file: UploadFile | None = File(None, description="Image file (required if type=image)"),
) -> ProfileOut:
    return await ProfileService(db).upload_banner(
        current_user,
        banner_type=type,
        color=color,
        file=file,
    )
