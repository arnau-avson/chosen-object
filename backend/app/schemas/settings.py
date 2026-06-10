from pydantic import BaseModel

from ..models.settings import UserSettings


class SettingsOut(BaseModel):
    push_notifications: bool = True
    email_notifications: bool = True
    order_updates: bool = True
    price_drops: bool = False
    new_followers: bool = True
    new_pieces: bool = True
    piece_updates: bool = True
    messages: bool = True
    rental_requests: bool = True
    rental_status_changes: bool = True
    show_profile_publicly: bool = True
    allow_messages_from_anyone: bool = False
    language: str = "en"

    model_config = {"from_attributes": True}

    @classmethod
    def from_model(cls, settings: UserSettings) -> "SettingsOut":
        return cls(
            push_notifications=settings.push_notifications,
            email_notifications=settings.email_notifications,
            order_updates=settings.order_updates,
            price_drops=settings.price_drops,
            new_followers=settings.new_followers,
            new_pieces=settings.new_pieces,
            piece_updates=settings.piece_updates,
            messages=settings.messages,
            rental_requests=settings.rental_requests,
            rental_status_changes=settings.rental_status_changes,
            show_profile_publicly=settings.show_profile_publicly,
            allow_messages_from_anyone=settings.allow_messages_from_anyone,
            language=settings.language,
        )

    @classmethod
    def defaults(cls) -> "SettingsOut":
        return cls()


class SettingsUpdate(BaseModel):
    push_notifications: bool | None = None
    email_notifications: bool | None = None
    order_updates: bool | None = None
    price_drops: bool | None = None
    new_followers: bool | None = None
    new_pieces: bool | None = None
    piece_updates: bool | None = None
    messages: bool | None = None
    rental_requests: bool | None = None
    rental_status_changes: bool | None = None
    show_profile_publicly: bool | None = None
    allow_messages_from_anyone: bool | None = None
    language: str | None = None
