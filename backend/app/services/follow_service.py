from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.follow_repository import FollowRepository
from ..schemas.follow import FollowCountsOut, FollowUserOut
from .notification_helper import notify


class FollowService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = FollowRepository(db)

    def follow_user(self, current_user: User, target_user_id: int) -> dict:
        if current_user.id == target_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot follow yourself.",
            )

        target = self.repo.get_user_by_id(target_user_id)
        if target is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        if self.repo.is_following(current_user.id, target_user_id):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Already following this user.",
            )

        self.repo.follow(current_user.id, target_user_id)

        notify(
            self.db,
            user_id=target_user_id,
            type="follow",
            title="New follower",
            body=f"{current_user.username} started following you.",
            reference_id=current_user.id,
            reference_type="user",
        )

        return {"following": True}

    def unfollow_user(self, current_user: User, target_user_id: int) -> dict:
        removed = self.repo.unfollow(current_user.id, target_user_id)
        if not removed:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Not following this user.",
            )
        return {"following": False}

    def get_followers(
        self, user_id: int, offset: int = 0, limit: int = 20
    ) -> list[FollowUserOut]:
        results = self.repo.get_followers(user_id, offset, limit)
        return [
            FollowUserOut.from_user(user, followed_at=follow.created_at)
            for user, follow in results
        ]

    def get_following(
        self, user_id: int, offset: int = 0, limit: int = 20
    ) -> list[FollowUserOut]:
        results = self.repo.get_following(user_id, offset, limit)
        return [
            FollowUserOut.from_user(user, followed_at=follow.created_at)
            for user, follow in results
        ]

    def get_counts(self, user_id: int) -> FollowCountsOut:
        return FollowCountsOut(
            followers_count=self.repo.get_followers_count(user_id),
            following_count=self.repo.get_following_count(user_id),
        )
