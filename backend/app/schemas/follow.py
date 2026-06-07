import base64
from datetime import datetime

from pydantic import BaseModel

from ..models.user import User


class FollowUserOut(BaseModel):
    id: int
    username: str
    studio_name: str | None = None
    discipline: str | None = None
    avatar_type: str = "color"
    avatar_color: str = "#2E2520"
    avatar_image_b64: str | None = None
    followed_at: datetime | None = None

    @classmethod
    def from_user(cls, user: User, followed_at: datetime | None = None) -> "FollowUserOut":
        avatar_b64 = None
        if user.avatar_image:
            avatar_b64 = base64.b64encode(user.avatar_image).decode("ascii")

        return cls(
            id=user.id,
            username=user.username,
            studio_name=user.studio_name,
            discipline=user.discipline,
            avatar_type=user.avatar_type,
            avatar_color=user.avatar_color,
            avatar_image_b64=avatar_b64,
            followed_at=followed_at,
        )


class FollowCountsOut(BaseModel):
    followers_count: int
    following_count: int
