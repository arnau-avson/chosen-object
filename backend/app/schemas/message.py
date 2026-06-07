import base64
from datetime import datetime

from pydantic import BaseModel

from ..models.user import User


class MessageOut(BaseModel):
    id: int
    conversation_id: int
    sender_id: int
    sender_username: str | None = None
    text: str
    reply_to_id: int | None = None
    reaction: str | None = None
    created_at: datetime


class ConversationOut(BaseModel):
    id: int
    other_user_id: int
    other_username: str | None = None
    other_avatar_type: str = "color"
    other_avatar_color: str = "#2E2520"
    other_avatar_image_b64: str | None = None
    last_message: str | None = None
    last_message_at: datetime | None = None
    unread_count: int = 0
    is_request: bool = False
    request_accepted: bool = False
    updated_at: datetime


class ConversationStartIn(BaseModel):
    user_id: int
    text: str | None = None


class SendMessageIn(BaseModel):
    text: str
    reply_to_id: int | None = None


class ReactionIn(BaseModel):
    reaction: str | None = None
