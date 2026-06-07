from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.collection import (
    CollectionCreate,
    CollectionDetailOut,
    CollectionOut,
    SavedPieceOut,
)
from app.services.collection_service import CollectionService

router = APIRouter(tags=["collections"])


# ── Saves ─────────────────────────────────────────────────────

@router.post(
    "/saves/{piece_id}",
    summary="Toggle save on a piece",
)
def toggle_save(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return CollectionService(db).toggle_save(current_user, piece_id)


@router.get(
    "/saves",
    response_model=list[SavedPieceOut],
    summary="List saved pieces",
)
def list_saved_pieces(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[SavedPieceOut]:
    return CollectionService(db).get_saved_pieces(current_user, offset, limit)


# ── Collections ───────────────────────────────────────────────

@router.post(
    "/collections",
    response_model=CollectionOut,
    status_code=201,
    summary="Create a collection",
)
def create_collection(
    data: CollectionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CollectionOut:
    return CollectionService(db).create_collection(current_user, data)


@router.get(
    "/collections",
    response_model=list[CollectionOut],
    summary="List collections",
)
def list_collections(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[CollectionOut]:
    return CollectionService(db).list_collections(current_user)


@router.get(
    "/collections/{collection_id}",
    response_model=CollectionDetailOut,
    summary="Get collection detail",
)
def get_collection(
    collection_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CollectionDetailOut:
    return CollectionService(db).get_collection_detail(current_user, collection_id)


@router.patch(
    "/collections/{collection_id}",
    response_model=CollectionOut,
    summary="Rename a collection",
)
def rename_collection(
    collection_id: int,
    data: CollectionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CollectionOut:
    return CollectionService(db).rename_collection(
        current_user, collection_id, data.name
    )


@router.delete(
    "/collections/{collection_id}",
    status_code=204,
    summary="Delete a collection",
)
def delete_collection(
    collection_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    CollectionService(db).delete_collection(current_user, collection_id)


@router.post(
    "/collections/{collection_id}/pieces/{piece_id}",
    summary="Add piece to collection",
)
def add_piece_to_collection(
    collection_id: int,
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return CollectionService(db).add_piece_to_collection(
        current_user, collection_id, piece_id
    )


@router.delete(
    "/collections/{collection_id}/pieces/{piece_id}",
    status_code=204,
    summary="Remove piece from collection",
)
def remove_piece_from_collection(
    collection_id: int,
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    CollectionService(db).remove_piece_from_collection(
        current_user, collection_id, piece_id
    )
