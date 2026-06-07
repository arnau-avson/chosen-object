import io

from fastapi import HTTPException, UploadFile, status
from PIL import Image
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.piece_repository import PieceRepository
from ..schemas.piece import PieceCreate, PieceListOut, PieceOut, PieceUpdate

_PIECE_IMAGE_SIZE = (1200, 1200)
_MAX_BYTES = 5 * 1024 * 1024  # 5 MB upload limit per image
_MAX_IMAGES = 8


def _compress_piece_image(raw: bytes) -> bytes:
    """Resize and compress a piece image to WebP format."""
    img = Image.open(io.BytesIO(raw))
    img = img.convert("RGB")
    img.thumbnail(_PIECE_IMAGE_SIZE, Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format="WEBP", quality=82)
    return buf.getvalue()


class PieceService:
    def __init__(self, db: Session) -> None:
        self.repo = PieceRepository(db)

    def list_pieces(self, user: User) -> list[PieceListOut]:
        pieces = self.repo.get_by_user(user.id)
        return [PieceListOut.from_model(p) for p in pieces]

    def get_piece(self, user: User, piece_id: int) -> PieceOut:
        piece = self.repo.get_by_id(piece_id, user.id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )
        return PieceOut.from_model(piece)

    def create_piece(self, user: User, data: PieceCreate) -> PieceOut:
        piece = self.repo.create(user.id, data.model_dump())
        return PieceOut.from_model(piece)

    async def upload_images(
        self,
        user: User,
        piece_id: int,
        files: list[UploadFile],
    ) -> PieceOut:
        piece = self.repo.get_by_id(piece_id, user.id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )

        existing_count = len(piece.images)
        if existing_count + len(files) > _MAX_IMAGES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Maximum {_MAX_IMAGES} images per piece. Currently {existing_count}.",
            )

        for i, file in enumerate(files):
            raw = await file.read()
            if len(raw) > _MAX_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail=f"Image #{i + 1} exceeds 5 MB limit.",
                )
            compressed = _compress_piece_image(raw)
            self.repo.add_image(
                piece.id, position=existing_count + i, image_data=compressed
            )

        # Refresh to include new images
        piece = self.repo.get_by_id(piece_id, user.id)
        return PieceOut.from_model(piece)

    def update_piece(self, user: User, piece_id: int, data: PieceUpdate) -> PieceOut:
        piece = self.repo.get_by_id(piece_id, user.id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )
        updates = data.model_dump(exclude_none=True)
        if not updates:
            return PieceOut.from_model(piece)
        piece = self.repo.update(piece, updates)
        return PieceOut.from_model(piece)

    def delete_image(self, user: User, piece_id: int, image_id: int) -> PieceOut:
        piece = self.repo.get_by_id(piece_id, user.id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )
        image = self.repo.get_image(image_id, piece_id)
        if image is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found.",
            )
        self.repo.delete_image(image)
        piece = self.repo.get_by_id(piece_id, user.id)
        return PieceOut.from_model(piece)

    def delete_piece(self, user: User, piece_id: int) -> None:
        piece = self.repo.get_by_id(piece_id, user.id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )
        self.repo.delete(piece)
