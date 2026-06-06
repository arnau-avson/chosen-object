import base64
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from ..models.user import User


class ProfileOut(BaseModel):
    id: int
    username: str
    email: EmailStr
    role: str
    first_name: str | None = None
    last_name: str | None = None
    city: str | None = None
    country: str | None = None

    # Studio
    handle: str | None = None
    studio_name: str | None = None
    discipline: str | None = None
    bio: str | None = None

    # Online presence
    website: str | None = None
    instagram: str | None = None
    portfolio: str | None = None

    # Invoicing
    legal_entity: str | None = None
    vat_id: str | None = None
    iban: str | None = None
    invoice_prefix: str | None = None

    # Avatar
    avatar_type: str = "color"
    avatar_color: str = "#2E2520"
    avatar_image_b64: str | None = None

    # Banner
    banner_type: str = "color"
    banner_color: str = "#4A3F35"
    banner_image_b64: str | None = None

    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_user(cls, user: User) -> "ProfileOut":
        avatar_b64 = None
        if user.avatar_image is not None:
            avatar_b64 = base64.b64encode(user.avatar_image).decode("ascii")

        banner_b64 = None
        if user.banner_image is not None:
            banner_b64 = base64.b64encode(user.banner_image).decode("ascii")

        return cls(
            id=user.id,
            username=user.username,
            email=user.email,
            role=user.role,
            first_name=user.first_name,
            last_name=user.last_name,
            city=user.city,
            country=user.country,
            handle=user.handle,
            studio_name=user.studio_name,
            discipline=user.discipline,
            bio=user.bio,
            website=user.website,
            instagram=user.instagram,
            portfolio=user.portfolio,
            legal_entity=user.legal_entity,
            vat_id=user.vat_id,
            iban=user.iban,
            invoice_prefix=user.invoice_prefix,
            avatar_type=user.avatar_type,
            avatar_color=user.avatar_color,
            avatar_image_b64=avatar_b64,
            banner_type=user.banner_type,
            banner_color=user.banner_color,
            banner_image_b64=banner_b64,
            created_at=user.created_at,
            updated_at=user.updated_at,
        )


class ProfileUpdate(BaseModel):
    username: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    city: str | None = None
    country: str | None = None
    handle: str | None = None
    studio_name: str | None = None
    discipline: str | None = None
    bio: str | None = None
    website: str | None = None
    instagram: str | None = None
    portfolio: str | None = None
    legal_entity: str | None = None
    vat_id: str | None = None
    iban: str | None = None
    invoice_prefix: str | None = None
