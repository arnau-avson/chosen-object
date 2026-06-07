import base64
import json
from datetime import datetime

from pydantic import BaseModel

from ..models.piece import Piece
from ..models.user import User


class BrowsePieceOut(BaseModel):
    id: int
    user_id: int
    title: str
    discipline: str | None = None
    year: str | None = None
    edition: str | None = None
    description: str | None = None
    price_cents: int
    old_price_cents: int | None = None
    rental: bool
    rental_daily_rate_cents: int | None = None
    stock: int
    ships_to: list[str] | None = None
    packaging: str | None = None
    status: str
    cover_image_b64: str | None = None
    created_at: datetime
    is_saved: bool = False
    seller_username: str | None = None
    seller_studio_name: str | None = None
    seller_city: str | None = None
    seller_country: str | None = None

    @classmethod
    def from_model(
        cls,
        piece: Piece,
        seller: User | None = None,
        is_saved: bool = False,
    ) -> "BrowsePieceOut":
        ships_to_list = None
        if piece.ships_to:
            ships_to_list = json.loads(piece.ships_to)

        cover_b64 = None
        if piece.images:
            first = min(piece.images, key=lambda img: img.position)
            cover_b64 = base64.b64encode(first.image_data).decode("ascii")

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
            rental=piece.rental,
            rental_daily_rate_cents=piece.rental_daily_rate_cents,
            stock=piece.stock,
            ships_to=ships_to_list,
            packaging=piece.packaging,
            status=piece.status,
            cover_image_b64=cover_b64,
            created_at=piece.created_at,
            is_saved=is_saved,
            seller_username=seller.username if seller else None,
            seller_studio_name=seller.studio_name if seller else None,
            seller_city=seller.city if seller else None,
            seller_country=seller.country if seller else None,
        )


class BrowsePieceDetailOut(BrowsePieceOut):
    """Full piece detail with all images."""

    images: list[dict] = []

    @classmethod
    def from_model(
        cls,
        piece: Piece,
        seller: User | None = None,
        is_saved: bool = False,
    ) -> "BrowsePieceDetailOut":
        ships_to_list = None
        if piece.ships_to:
            ships_to_list = json.loads(piece.ships_to)

        cover_b64 = None
        images_list = []
        if piece.images:
            sorted_imgs = sorted(piece.images, key=lambda img: img.position)
            cover_b64 = base64.b64encode(sorted_imgs[0].image_data).decode("ascii")
            images_list = [
                {
                    "id": img.id,
                    "position": img.position,
                    "image_b64": base64.b64encode(img.image_data).decode("ascii"),
                }
                for img in sorted_imgs
            ]

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
            rental=piece.rental,
            rental_daily_rate_cents=piece.rental_daily_rate_cents,
            stock=piece.stock,
            ships_to=ships_to_list,
            packaging=piece.packaging,
            status=piece.status,
            cover_image_b64=cover_b64,
            created_at=piece.created_at,
            is_saved=is_saved,
            seller_username=seller.username if seller else None,
            seller_studio_name=seller.studio_name if seller else None,
            seller_city=seller.city if seller else None,
            seller_country=seller.country if seller else None,
            images=images_list,
        )


class BrowseUserOut(BaseModel):
    id: int
    username: str
    studio_name: str | None = None
    discipline: str | None = None
    city: str | None = None
    country: str | None = None
    bio: str | None = None
    avatar_type: str = "color"
    avatar_color: str = "#2E2520"
    avatar_image_b64: str | None = None
    banner_type: str = "color"
    banner_color: str = "#4A3F35"
    banner_image_b64: str | None = None
    is_following: bool = False
    followers_count: int = 0
    following_count: int = 0
    pieces_count: int = 0

    @classmethod
    def from_model(
        cls,
        user: User,
        is_following: bool = False,
        followers_count: int = 0,
        following_count: int = 0,
        pieces_count: int = 0,
    ) -> "BrowseUserOut":
        avatar_b64 = None
        if user.avatar_image:
            avatar_b64 = base64.b64encode(user.avatar_image).decode("ascii")
        banner_b64 = None
        if user.banner_image:
            banner_b64 = base64.b64encode(user.banner_image).decode("ascii")

        return cls(
            id=user.id,
            username=user.username,
            studio_name=user.studio_name,
            discipline=user.discipline,
            city=user.city,
            country=user.country,
            bio=user.bio,
            avatar_type=user.avatar_type,
            avatar_color=user.avatar_color,
            avatar_image_b64=avatar_b64,
            banner_type=user.banner_type,
            banner_color=user.banner_color,
            banner_image_b64=banner_b64,
            is_following=is_following,
            followers_count=followers_count,
            following_count=following_count,
            pieces_count=pieces_count,
        )
