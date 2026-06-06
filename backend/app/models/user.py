from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Integer, LargeBinary, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True, autoincrement=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(20), nullable=False, default="collector")
    first_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    city: Mapped[str | None] = mapped_column(String(100), nullable=True)
    country: Mapped[str | None] = mapped_column(String(100), nullable=True)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    verification_pin: Mapped[str | None] = mapped_column(String(6), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # ── Profile / Studio ─────────────────────────────────────
    handle: Mapped[str | None] = mapped_column(String(50), unique=True, nullable=True)
    studio_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    discipline: Mapped[str | None] = mapped_column(String(50), nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)

    # ── Online presence ──────────────────────────────────────
    website: Mapped[str | None] = mapped_column(String(255), nullable=True)
    instagram: Mapped[str | None] = mapped_column(String(100), nullable=True)
    portfolio: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # ── Invoicing ────────────────────────────────────────────
    legal_entity: Mapped[str | None] = mapped_column(String(150), nullable=True)
    vat_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    iban: Mapped[str | None] = mapped_column(String(50), nullable=True)
    invoice_prefix: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # ── Avatar ───────────────────────────────────────────────
    avatar_type: Mapped[str] = mapped_column(String(10), nullable=False, default="color")
    avatar_color: Mapped[str] = mapped_column(String(7), nullable=False, default="#2E2520")
    avatar_image: Mapped[bytes | None] = mapped_column(LargeBinary(length=2**24 - 1), nullable=True)

    # ── Banner ───────────────────────────────────────────────
    banner_type: Mapped[str] = mapped_column(String(10), nullable=False, default="color")
    banner_color: Mapped[str] = mapped_column(String(7), nullable=False, default="#4A3F35")
    banner_image: Mapped[bytes | None] = mapped_column(LargeBinary(length=2**24 - 1), nullable=True)

    # ── Timestamps ───────────────────────────────────────────
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} username={self.username!r}>"
