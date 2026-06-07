import base64
from datetime import datetime

from pydantic import BaseModel

from ..models.piece import Piece


class CartItemOut(BaseModel):
    piece_id: int
    title: str
    discipline: str | None = None
    price_cents: int
    cover_image_b64: str | None = None
    seller_id: int
    seller_username: str | None = None
    added_at: datetime

    @classmethod
    def from_piece(
        cls,
        piece: Piece,
        added_at: datetime,
        seller_username: str | None = None,
    ) -> "CartItemOut":
        cover_b64 = None
        if piece.images:
            first = min(piece.images, key=lambda img: img.position)
            cover_b64 = base64.b64encode(first.image_data).decode("ascii")
        return cls(
            piece_id=piece.id,
            title=piece.title,
            discipline=piece.discipline,
            price_cents=piece.price_cents,
            cover_image_b64=cover_b64,
            seller_id=piece.user_id,
            seller_username=seller_username,
            added_at=added_at,
        )


class CartOut(BaseModel):
    items: list[CartItemOut]
    item_count: int
    total_cents: int
