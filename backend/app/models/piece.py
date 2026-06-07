from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    LargeBinary,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base


class Piece(Base):
    __tablename__ = "pieces"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    discipline: Mapped[str | None] = mapped_column(String(50), nullable=True)
    year: Mapped[str | None] = mapped_column(String(10), nullable=True)
    edition: Mapped[str | None] = mapped_column(String(50), nullable=True)
    price_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    old_price_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    cost_price_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    rental: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    stock: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    ships_to: Mapped[str | None] = mapped_column(Text, nullable=True)
    packaging: Mapped[str | None] = mapped_column(String(50), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    rental_daily_rate_cents: Mapped[int | None] = mapped_column(
        Integer, nullable=True
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="active"
    )

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

    images: Mapped[list["PieceImage"]] = relationship(
        "PieceImage",
        back_populates="piece",
        cascade="all, delete-orphan",
        order_by="PieceImage.position",
    )


class PieceImage(Base):
    __tablename__ = "piece_images"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    piece_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("pieces.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    position: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    image_data: Mapped[bytes] = mapped_column(
        LargeBinary(length=2**24 - 1), nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    piece: Mapped["Piece"] = relationship("Piece", back_populates="images")
