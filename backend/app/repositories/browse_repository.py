from sqlalchemy import func
from sqlalchemy.orm import Session, defer, joinedload

from ..models.collection import Save
from ..models.follow import Follow
from ..models.piece import Piece
from ..models.user import User


class BrowseRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    # ── Piece queries ──────────────────────────────────────────

    def browse_pieces(
        self,
        search: str | None = None,
        discipline: str | None = None,
        sort: str | None = None,
        min_price: int | None = None,
        max_price: int | None = None,
        piece_type: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[Piece]:
        q = (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.status == "active", Piece.stock > 0, Piece.is_hidden == False)
        )

        if search:
            q = q.filter(Piece.title.ilike(f"%{search}%"))
        if discipline:
            q = q.filter(Piece.discipline == discipline)
        if min_price is not None:
            q = q.filter(Piece.price_cents >= min_price)
        if max_price is not None:
            q = q.filter(Piece.price_cents <= max_price)
        if piece_type == "buy":
            q = q.filter(Piece.rental == False)
        elif piece_type == "rent":
            q = q.filter(Piece.rental == True)

        if sort == "price_asc":
            q = q.order_by(Piece.price_cents.asc())
        elif sort == "price_desc":
            q = q.order_by(Piece.price_cents.desc())
        elif sort == "oldest":
            q = q.order_by(Piece.created_at.asc())
        elif sort == "random":
            q = q.order_by(func.rand())
        else:
            q = q.order_by(Piece.created_at.desc())

        return q.offset(offset).limit(limit).all()

    def get_piece_by_id(self, piece_id: int) -> Piece | None:
        return (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.id == piece_id, Piece.status == "active", Piece.is_hidden == False)
            .first()
        )

    def get_user_pieces(
        self, user_id: int, offset: int = 0, limit: int = 20
    ) -> list[Piece]:
        return (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.user_id == user_id, Piece.status == "active", Piece.is_hidden == False)
            .order_by(Piece.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

    # ── User queries ───────────────────────────────────────────

    def get_user_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id, User.is_active == True).first()

    def search_users(
        self,
        search: str | None = None,
        exclude_user_id: int | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[User]:
        q = self.db.query(User).filter(User.is_active == True)

        if exclude_user_id is not None:
            q = q.filter(User.id != exclude_user_id)

        if search:
            q = q.filter(
                (User.username.ilike(f"%{search}%"))
                | (User.studio_name.ilike(f"%{search}%"))
            )

        return q.order_by(User.created_at.desc()).offset(offset).limit(limit).all()

    # ── Single-item checks (kept for single-detail endpoints) ──

    def is_saved(self, user_id: int, piece_id: int) -> bool:
        return (
            self.db.query(Save)
            .filter(Save.user_id == user_id, Save.piece_id == piece_id)
            .first()
            is not None
        )

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

    def get_pieces_count(self, user_id: int) -> int:
        return (
            self.db.query(func.count(Piece.id))
            .filter(Piece.user_id == user_id, Piece.status == "active", Piece.is_hidden == False)
            .scalar()
            or 0
        )

    # ── Batch queries (N+1 elimination) ────────────────────────

    def get_saved_piece_ids(self, user_id: int, piece_ids: list[int]) -> set[int]:
        """Return the subset of piece_ids that the user has saved. 1 query."""
        if not piece_ids:
            return set()
        rows = (
            self.db.query(Save.piece_id)
            .filter(Save.user_id == user_id, Save.piece_id.in_(piece_ids))
            .all()
        )
        return {r[0] for r in rows}

    def get_sellers_by_ids(self, user_ids: list[int]) -> dict[int, User]:
        """Load multiple users by ID, deferring heavy BLOB columns. 1 query."""
        if not user_ids:
            return {}
        users = (
            self.db.query(User)
            .options(defer(User.avatar_image), defer(User.banner_image))
            .filter(User.id.in_(user_ids), User.is_active == True)
            .all()
        )
        return {u.id: u for u in users}

    def get_following_set(self, follower_id: int, candidate_ids: list[int]) -> set[int]:
        """Return which of candidate_ids the follower is following. 1 query."""
        if not candidate_ids:
            return set()
        rows = (
            self.db.query(Follow.following_id)
            .filter(
                Follow.follower_id == follower_id,
                Follow.following_id.in_(candidate_ids),
            )
            .all()
        )
        return {r[0] for r in rows}

    def get_followers_set(self, following_id: int, candidate_ids: list[int]) -> set[int]:
        """Return which of candidate_ids follow the following_id. 1 query."""
        if not candidate_ids:
            return set()
        rows = (
            self.db.query(Follow.follower_id)
            .filter(
                Follow.following_id == following_id,
                Follow.follower_id.in_(candidate_ids),
            )
            .all()
        )
        return {r[0] for r in rows}

    def get_bulk_followers_counts(self, user_ids: list[int]) -> dict[int, int]:
        """Return {user_id: followers_count} for all user_ids. 1 query."""
        if not user_ids:
            return {}
        rows = (
            self.db.query(Follow.following_id, func.count(Follow.id))
            .filter(Follow.following_id.in_(user_ids))
            .group_by(Follow.following_id)
            .all()
        )
        counts = {uid: 0 for uid in user_ids}
        for uid, cnt in rows:
            counts[uid] = cnt
        return counts

    def get_bulk_following_counts(self, user_ids: list[int]) -> dict[int, int]:
        """Return {user_id: following_count} for all user_ids. 1 query."""
        if not user_ids:
            return {}
        rows = (
            self.db.query(Follow.follower_id, func.count(Follow.id))
            .filter(Follow.follower_id.in_(user_ids))
            .group_by(Follow.follower_id)
            .all()
        )
        counts = {uid: 0 for uid in user_ids}
        for uid, cnt in rows:
            counts[uid] = cnt
        return counts

    def get_bulk_pieces_counts(self, user_ids: list[int]) -> dict[int, int]:
        """Return {user_id: pieces_count} for all user_ids. 1 query."""
        if not user_ids:
            return {}
        rows = (
            self.db.query(Piece.user_id, func.count(Piece.id))
            .filter(
                Piece.user_id.in_(user_ids),
                Piece.status == "active",
                Piece.is_hidden == False,
            )
            .group_by(Piece.user_id)
            .all()
        )
        counts = {uid: 0 for uid in user_ids}
        for uid, cnt in rows:
            counts[uid] = cnt
        return counts
