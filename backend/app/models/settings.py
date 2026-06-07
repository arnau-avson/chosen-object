from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base


class UserSettings(Base):
    __tablename__ = "user_settings"

    id: Mapped[int] = mapped_column(
        Integer, primary_key=True, index=True, autoincrement=True
    )
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    push_notifications: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    email_notifications: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    order_updates: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    price_drops: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    new_followers: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    show_profile_publicly: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    allow_messages_from_anyone: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    language: Mapped[str] = mapped_column(
        String(20), nullable=False, default="en"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
