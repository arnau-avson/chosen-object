from typing import Annotated

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.piece import PieceCreate, PieceListOut, PieceOut, PieceUpdate
from app.services.piece_service import PieceService

router = APIRouter(prefix="/pieces", tags=["pieces"])


@router.get(
    "",
    response_model=list[PieceListOut],
    summary="List current user's pieces",
)
def list_pieces(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[PieceListOut]:
    return PieceService(db).list_pieces(current_user)


@router.post(
    "",
    response_model=PieceOut,
    status_code=201,
    summary="Create a new piece (metadata only)",
)
def create_piece(
    data: PieceCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> PieceOut:
    return PieceService(db).create_piece(current_user, data)


@router.get(
    "/{piece_id}",
    response_model=PieceOut,
    summary="Get a piece by ID",
)
def get_piece(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> PieceOut:
    return PieceService(db).get_piece(current_user, piece_id)


@router.post(
    "/{piece_id}/images",
    response_model=PieceOut,
    summary="Upload images for a piece (up to 8 total)",
)
async def upload_piece_images(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    files: list[UploadFile] = File(..., description="Image files (up to 8)"),
) -> PieceOut:
    return await PieceService(db).upload_images(current_user, piece_id, files)


@router.patch(
    "/{piece_id}",
    response_model=PieceOut,
    summary="Update piece metadata",
)
def update_piece(
    piece_id: int,
    data: PieceUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> PieceOut:
    return PieceService(db).update_piece(current_user, piece_id, data)


@router.patch(
    "/{piece_id}/toggle-hidden",
    response_model=PieceOut,
    summary="Toggle piece visibility (hidden/visible)",
)
def toggle_piece_hidden(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> PieceOut:
    return PieceService(db).toggle_hidden(current_user, piece_id)


@router.delete(
    "/{piece_id}/images/{image_id}",
    response_model=PieceOut,
    summary="Delete a single image from a piece",
)
def delete_piece_image(
    piece_id: int,
    image_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> PieceOut:
    return PieceService(db).delete_image(current_user, piece_id, image_id)


@router.delete(
    "/{piece_id}",
    status_code=204,
    summary="Delete a piece",
)
def delete_piece(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    PieceService(db).delete_piece(current_user, piece_id)
