import base64
from datetime import datetime

from pydantic import BaseModel

from ..models.collection import Collection
from ..models.piece import Piece


class SavedPieceOut(BaseModel):
    id: int
    title: str
    discipline: str | None = None
    price_cents: int
    cover_image_b64: str | None = None
    saved_at: datetime

    @classmethod
    def from_piece(cls, piece: Piece, saved_at: datetime) -> "SavedPieceOut":
        cover_b64 = None
        if piece.images:
            first = min(piece.images, key=lambda img: img.position)
            cover_b64 = base64.b64encode(first.image_data).decode("ascii")
        return cls(
            id=piece.id,
            title=piece.title,
            discipline=piece.discipline,
            price_cents=piece.price_cents,
            cover_image_b64=cover_b64,
            saved_at=saved_at,
        )


class CollectionCreate(BaseModel):
    name: str


class CollectionOut(BaseModel):
    id: int
    name: str
    piece_count: int = 0
    created_at: datetime

    @classmethod
    def from_model(cls, collection: Collection) -> "CollectionOut":
        return cls(
            id=collection.id,
            name=collection.name,
            piece_count=len(collection.pieces) if collection.pieces else 0,
            created_at=collection.created_at,
        )


class CollectionDetailOut(CollectionOut):
    pieces: list[SavedPieceOut] = []
