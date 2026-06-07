from datetime import date

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session, joinedload

from ..models.piece import Piece
from ..models.rental import Rental
from ..models.user import User


class RentalRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        piece_id: int,
        renter_id: int,
        owner_id: int,
        start_date: date,
        end_date: date,
        daily_rate_cents: int,
        total_cents: int,
        notes: str | None = None,
    ) -> Rental:
        rental = Rental(
            piece_id=piece_id,
            renter_id=renter_id,
            owner_id=owner_id,
            start_date=start_date,
            end_date=end_date,
            daily_rate_cents=daily_rate_cents,
            total_cents=total_cents,
            notes=notes,
        )
        self.db.add(rental)
        self.db.commit()
        self.db.refresh(rental)
        return rental

    def get_by_id(self, rental_id: int) -> Rental | None:
        return self.db.query(Rental).filter(Rental.id == rental_id).first()

    def list_rentals(
        self,
        user_id: int,
        role: str = "renter",
        status_filter: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[Rental]:
        q = self.db.query(Rental)

        if role == "owner":
            q = q.filter(Rental.owner_id == user_id)
        else:
            q = q.filter(Rental.renter_id == user_id)

        if status_filter:
            q = q.filter(Rental.status == status_filter)

        return q.order_by(Rental.created_at.desc()).offset(offset).limit(limit).all()

    def has_overlap(
        self, piece_id: int, start_date: date, end_date: date
    ) -> bool:
        """Check if there's an accepted/active rental overlapping the date range."""
        overlap = (
            self.db.query(Rental)
            .filter(
                Rental.piece_id == piece_id,
                Rental.status.in_(["accepted", "active"]),
                and_(
                    Rental.start_date <= end_date,
                    Rental.end_date >= start_date,
                ),
            )
            .first()
        )
        return overlap is not None

    def get_blocked_dates(self, piece_id: int, year: int, month: int) -> list[Rental]:
        """Get all non-cancelled rentals for a piece in a given month."""
        from calendar import monthrange

        _, last_day = monthrange(year, month)
        month_start = date(year, month, 1)
        month_end = date(year, month, last_day)

        return (
            self.db.query(Rental)
            .filter(
                Rental.piece_id == piece_id,
                Rental.status.in_(["pending", "accepted", "active"]),
                and_(
                    Rental.start_date <= month_end,
                    Rental.end_date >= month_start,
                ),
            )
            .all()
        )

    def update(self, rental: Rental, data: dict) -> Rental:
        for key, value in data.items():
            setattr(rental, key, value)
        self.db.commit()
        self.db.refresh(rental)
        return rental

    def get_piece(self, piece_id: int) -> Piece | None:
        return (
            self.db.query(Piece)
            .filter(Piece.id == piece_id, Piece.status == "active")
            .first()
        )

    def get_user_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()
