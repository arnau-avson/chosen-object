import base64
import json
from datetime import datetime

from pydantic import BaseModel

from ..models.piece import Piece, PieceImage


class PieceImageOut(BaseModel):
    id: int
    position: int
    image_b64: str

    model_config = {"from_attributes": True}

    @classmethod
    def from_model(cls, img: PieceImage) -> "PieceImageOut":
        return cls(
            id=img.id,
            position=img.position,
            image_b64=base64.b64encode(img.image_data).decode("ascii"),
        )


class PieceCreate(BaseModel):
    title: str
    discipline: str | None = None
    year: str | None = None
    edition: str | None = None
    description: str | None = None
    price_cents: int
    old_price_cents: int | None = None
    cost_price_cents: int | None = None
    rental: bool = False
    rental_daily_rate_cents: int | None = None
    stock: int = 1
    ships_to: list[str] | None = None
    packaging: str | None = None


class PieceUpdate(BaseModel):
    title: str | None = None
    discipline: str | None = None
    year: str | None = None
    edition: str | None = None
    description: str | None = None
    price_cents: int | None = None
    old_price_cents: int | None = None
    cost_price_cents: int | None = None
    rental: bool | None = None
    rental_daily_rate_cents: int | None = None
    stock: int | None = None
    ships_to: list[str] | None = None
    packaging: str | None = None


class PieceOut(BaseModel):
    id: int
    user_id: int
    title: str
    discipline: str | None = None
    year: str | None = None
    edition: str | None = None
    description: str | None = None
    price_cents: int
    old_price_cents: int | None = None
    cost_price_cents: int | None = None
    rental: bool
    rental_daily_rate_cents: int | None = None
    stock: int
    ships_to: list[str] | None = None
    packaging: str | None = None
    status: str
    images: list[PieceImageOut] = []
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_model(cls, piece: Piece) -> "PieceOut":
        ships_to_list = None
        if piece.ships_to:
            ships_to_list = json.loads(piece.ships_to)

        return cls(
            id=piece.id,
            user_id=piece.user_id,
            title=piece.title,
            discipline=piece.discipline,
            year=piece.year,
            edition=piece.edition,
            description=piece.description,
            price_cents=piece.price_cents,
            old_price_cents=piece.old_price_cents,
            cost_price_cents=piece.cost_price_cents,
            rental=piece.rental,
            rental_daily_rate_cents=piece.rental_daily_rate_cents,
            stock=piece.stock,
            ships_to=ships_to_list,
            packaging=piece.packaging,
            status=piece.status,
            images=[PieceImageOut.from_model(img) for img in piece.images],
            created_at=piece.created_at,
            updated_at=piece.updated_at,
        )


class PieceListOut(BaseModel):
    """Lighter version without full image data for list endpoints."""

    id: int
    title: str
    discipline: str | None = None
    year: str | None = None
    price_cents: int
    rental: bool
    status: str
    cover_image_b64: str | None = None
    created_at: datetime

    @classmethod
    def from_model(cls, piece: Piece) -> "PieceListOut":
        cover_b64 = None
        if piece.images:
            first = min(piece.images, key=lambda img: img.position)
            cover_b64 = base64.b64encode(first.image_data).decode("ascii")

        return cls(
            id=piece.id,
            title=piece.title,
            discipline=piece.discipline,
            year=piece.year,
            price_cents=piece.price_cents,
            rental=piece.rental,
            status=piece.status,
            cover_image_b64=cover_b64,
            created_at=piece.created_at,
        )
