from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.browse_repository import BrowseRepository
from ..schemas.browse import BrowsePieceDetailOut, BrowsePieceOut, BrowseUserOut


class BrowseService:
    def __init__(self, db: Session) -> None:
        self.repo = BrowseRepository(db)

    def browse_pieces(
        self,
        current_user: User | None,
        search: str | None = None,
        discipline: str | None = None,
        sort: str | None = None,
        min_price: int | None = None,
        max_price: int | None = None,
        piece_type: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[BrowsePieceOut]:
        pieces = self.repo.browse_pieces(
            search=search,
            discipline=discipline,
            sort=sort,
            min_price=min_price,
            max_price=max_price,
            piece_type=piece_type,
            offset=offset,
            limit=limit,
        )

        results = []
        for piece in pieces:
            is_saved = False
            if current_user:
                is_saved = self.repo.is_saved(current_user.id, piece.id)

            seller = self.repo.get_user_by_id(piece.user_id)
            results.append(
                BrowsePieceOut.from_model(piece, seller=seller, is_saved=is_saved)
            )
        return results

    def get_piece_detail(
        self, piece_id: int, current_user: User | None
    ) -> BrowsePieceDetailOut:
        piece = self.repo.get_piece_by_id(piece_id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )

        is_saved = False
        if current_user:
            is_saved = self.repo.is_saved(current_user.id, piece.id)

        seller = self.repo.get_user_by_id(piece.user_id)
        return BrowsePieceDetailOut.from_model(piece, seller=seller, is_saved=is_saved)

    def search_users(
        self,
        current_user: User | None,
        search: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[BrowseUserOut]:
        users = self.repo.search_users(
            search=search,
            exclude_user_id=current_user.id if current_user else None,
            offset=offset,
            limit=limit,
        )

        results = []
        for user in users:
            is_following = False
            if current_user and current_user.id != user.id:
                is_following = self.repo.is_following(current_user.id, user.id)

            followers_count = self.repo.get_followers_count(user.id)
            following_count = self.repo.get_following_count(user.id)
            pieces_count = self.repo.get_pieces_count(user.id)

            results.append(
                BrowseUserOut.from_model(
                    user,
                    is_following=is_following,
                    followers_count=followers_count,
                    following_count=following_count,
                    pieces_count=pieces_count,
                )
            )
        return results

    def get_user_pieces(
        self,
        user_id: int,
        current_user: User | None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[BrowsePieceOut]:
        pieces = self.repo.get_user_pieces(user_id, offset=offset, limit=limit)
        results = []
        for piece in pieces:
            is_saved = False
            if current_user:
                is_saved = self.repo.is_saved(current_user.id, piece.id)
            seller = self.repo.get_user_by_id(piece.user_id)
            results.append(
                BrowsePieceOut.from_model(piece, seller=seller, is_saved=is_saved)
            )
        return results

    def get_user_profile(
        self, user_id: int, current_user: User | None
    ) -> BrowseUserOut:
        user = self.repo.get_user_by_id(user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        is_following = False
        if current_user and current_user.id != user.id:
            is_following = self.repo.is_following(current_user.id, user.id)

        followers_count = self.repo.get_followers_count(user.id)
        following_count = self.repo.get_following_count(user.id)
        pieces_count = self.repo.get_pieces_count(user.id)

        return BrowseUserOut.from_model(
            user,
            is_following=is_following,
            followers_count=followers_count,
            following_count=following_count,
            pieces_count=pieces_count,
        )
