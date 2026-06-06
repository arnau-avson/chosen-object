from sqlalchemy.orm import Session

from ..models.user import User


class ProfileRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()

    def update_fields(self, user: User, data: dict) -> User:
        for key, value in data.items():
            if hasattr(user, key):
                setattr(user, key, value)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_avatar(
        self,
        user: User,
        avatar_type: str,
        avatar_color: str | None = None,
        avatar_image: bytes | None = None,
    ) -> User:
        user.avatar_type = avatar_type
        if avatar_color is not None:
            user.avatar_color = avatar_color
        if avatar_type == "image":
            user.avatar_image = avatar_image
        elif avatar_type == "color":
            user.avatar_image = None
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_banner(
        self,
        user: User,
        banner_type: str,
        banner_color: str | None = None,
        banner_image: bytes | None = None,
    ) -> User:
        user.banner_type = banner_type
        if banner_color is not None:
            user.banner_color = banner_color
        if banner_type == "image":
            user.banner_image = banner_image
        elif banner_type == "color":
            user.banner_image = None
        self.db.commit()
        self.db.refresh(user)
        return user
