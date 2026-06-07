from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.follow import FollowCountsOut, FollowUserOut
from app.services.follow_service import FollowService

router = APIRouter(prefix="/follows", tags=["follows"])


@router.post(
    "/{user_id}",
    summary="Follow a user",
)
def follow_user(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return FollowService(db).follow_user(current_user, user_id)


@router.delete(
    "/{user_id}",
    summary="Unfollow a user",
)
def unfollow_user(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return FollowService(db).unfollow_user(current_user, user_id)


@router.get(
    "/{user_id}/followers",
    response_model=list[FollowUserOut],
    summary="Get followers of a user",
)
def get_followers(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[FollowUserOut]:
    return FollowService(db).get_followers(user_id, offset, limit)


@router.get(
    "/{user_id}/following",
    response_model=list[FollowUserOut],
    summary="Get users followed by a user",
)
def get_following(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[FollowUserOut]:
    return FollowService(db).get_following(user_id, offset, limit)


@router.get(
    "/{user_id}/counts",
    response_model=FollowCountsOut,
    summary="Get follow counts for a user",
)
def get_follow_counts(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> FollowCountsOut:
    return FollowService(db).get_counts(user_id)
