from sqlalchemy import func
from sqlalchemy.orm import Session

from ..models.follow import Follow
from ..models.user import User


class FollowRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def follow(self, follower_id: int, following_id: int) -> Follow:
        follow = Follow(follower_id=follower_id, following_id=following_id)
        self.db.add(follow)
        self.db.commit()
        self.db.refresh(follow)
        return follow

    def unfollow(self, follower_id: int, following_id: int) -> bool:
        follow = (
            self.db.query(Follow)
            .filter(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id,
            )
            .first()
        )
        if follow is None:
            return False
        self.db.delete(follow)
        self.db.commit()
        return True

    def is_following(self, follower_id: int, following_id: int) -> bool:
        return (
            self.db.query(Follow)
            .filter(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id,
            )
            .first()
            is not None
        )

    def get_followers(
        self, user_id: int, offset: int = 0, limit: int = 20
    ) -> list[tuple[User, Follow]]:
        results = (
            self.db.query(User, Follow)
            .join(Follow, Follow.follower_id == User.id)
            .filter(Follow.following_id == user_id)
            .order_by(Follow.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return results

    def get_following(
        self, user_id: int, offset: int = 0, limit: int = 20
    ) -> list[tuple[User, Follow]]:
        results = (
            self.db.query(User, Follow)
            .join(Follow, Follow.following_id == User.id)
            .filter(Follow.follower_id == user_id)
            .order_by(Follow.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return results

    def get_followers_count(self, user_id: int) -> int:
        return (
            self.db.query(func.count(Follow.id))
            .filter(Follow.following_id == user_id)
            .scalar()
            or 0
        )

    def get_following_count(self, user_id: int) -> int:
        return (
            self.db.query(func.count(Follow.id))
            .filter(Follow.follower_id == user_id)
            .scalar()
            or 0
        )

    def get_user_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id, User.is_active == True).first()
