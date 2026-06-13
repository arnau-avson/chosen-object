from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_optional_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.browse import BrowsePieceDetailOut, BrowsePieceOut, BrowseUserOut
from app.services.browse_service import BrowseService

router = APIRouter(prefix="/browse", tags=["browse"])


@router.get(
    "/pieces",
    response_model=list[BrowsePieceOut],
    summary="Browse/search pieces (public)",
)
def browse_pieces(
    current_user: Annotated[User | None, Depends(get_optional_user)],
    db: Annotated[Session, Depends(get_db)],
    search: str | None = None,
    discipline: str | None = None,
    sort: str | None = None,
    min_price: int | None = None,
    max_price: int | None = None,
    piece_type: str | None = None,
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[BrowsePieceOut]:
    return BrowseService(db).browse_pieces(
        current_user=current_user,
        search=search,
        discipline=discipline,
        sort=sort,
        min_price=min_price,
        max_price=max_price,
        piece_type=piece_type,
        offset=offset,
        limit=limit,
    )


@router.get(
    "/pieces/{piece_id}",
    response_model=BrowsePieceDetailOut,
    summary="Get piece detail (public)",
)
def get_piece_detail(
    piece_id: int,
    current_user: Annotated[User | None, Depends(get_optional_user)],
    db: Annotated[Session, Depends(get_db)],
) -> BrowsePieceDetailOut:
    return BrowseService(db).get_piece_detail(piece_id, current_user)


@router.get(
    "/users",
    response_model=list[BrowseUserOut],
    summary="Search users (public)",
)
def search_users(
    current_user: Annotated[User | None, Depends(get_optional_user)],
    db: Annotated[Session, Depends(get_db)],
    search: str | None = None,
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[BrowseUserOut]:
    return BrowseService(db).search_users(
        current_user=current_user,
        search=search,
        offset=offset,
        limit=limit,
    )


@router.get(
    "/users/{user_id}",
    response_model=BrowseUserOut,
    summary="Get user profile (public)",
)
def get_user_profile(
    user_id: int,
    current_user: Annotated[User | None, Depends(get_optional_user)],
    db: Annotated[Session, Depends(get_db)],
) -> BrowseUserOut:
    return BrowseService(db).get_user_profile(user_id, current_user)


@router.get(
    "/users/{user_id}/pieces",
    response_model=list[BrowsePieceOut],
    summary="Get pieces by user (public)",
)
def get_user_pieces(
    user_id: int,
    current_user: Annotated[User | None, Depends(get_optional_user)],
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[BrowsePieceOut]:
    return BrowseService(db).get_user_pieces(
        user_id, current_user, offset=offset, limit=limit
    )
