from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.rental_repository import RentalRepository
from ..repositories.settings_repository import SettingsRepository
from ..schemas.rental import (
    BlockedDateRange,
    RentalCalendarOut,
    RentalCreate,
    RentalOut,
    RentalRespondIn,
    RentalStatusUpdate,
)
from .notification_helper import notify


class RentalService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = RentalRepository(db)

    def _rental_to_out(self, rental) -> RentalOut:
        piece = self.repo.get_piece(rental.piece_id)
        renter = self.repo.get_user_by_id(rental.renter_id)
        owner = self.repo.get_user_by_id(rental.owner_id)
        return RentalOut(
            id=rental.id,
            piece_id=rental.piece_id,
            piece_title=piece.title if piece else None,
            renter_id=rental.renter_id,
            renter_username=renter.username if renter else None,
            owner_id=rental.owner_id,
            owner_username=owner.username if owner else None,
            status=rental.status,
            start_date=rental.start_date,
            end_date=rental.end_date,
            daily_rate_cents=rental.daily_rate_cents,
            total_cents=rental.total_cents,
            notes=rental.notes,
            created_at=rental.created_at,
            updated_at=rental.updated_at,
        )

    def create_rental(self, user: User, data: RentalCreate) -> RentalOut:
        piece = self.repo.get_piece(data.piece_id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )

        if not piece.rental:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This piece is not available for rental.",
            )

        if piece.user_id == user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot rent your own piece.",
            )

        if data.start_date >= data.end_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="End date must be after start date.",
            )

        # Check availability
        if self.repo.has_overlap(data.piece_id, data.start_date, data.end_date):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Piece is not available for the selected dates.",
            )

        # Calculate total
        days = (data.end_date - data.start_date).days
        daily_rate = piece.rental_daily_rate_cents or piece.price_cents
        total = daily_rate * days

        rental = self.repo.create(
            piece_id=data.piece_id,
            renter_id=user.id,
            owner_id=piece.user_id,
            start_date=data.start_date,
            end_date=data.end_date,
            daily_rate_cents=daily_rate,
            total_cents=total,
            notes=data.notes,
        )

        # Notify owner (gated by rental_requests setting)
        settings_repo = SettingsRepository(self.db)
        owner_settings = settings_repo.get_by_user(piece.user_id)
        if not owner_settings or owner_settings.rental_requests:
            notify(
                self.db,
                user_id=piece.user_id,
                type="rental",
                title="New rental request",
                body=f"{user.username} wants to rent '{piece.title}'.",
                reference_id=rental.id,
                reference_type="rental",
            )

        return self._rental_to_out(rental)

    def list_rentals(
        self,
        user: User,
        role: str = "renter",
        status_filter: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[RentalOut]:
        rentals = self.repo.list_rentals(user.id, role, status_filter, offset, limit)
        return [self._rental_to_out(r) for r in rentals]

    def get_rental(self, user: User, rental_id: int) -> RentalOut:
        rental = self.repo.get_by_id(rental_id)
        if rental is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rental not found.",
            )

        if rental.renter_id != user.id and rental.owner_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized.",
            )

        return self._rental_to_out(rental)

    def respond_to_rental(
        self, user: User, rental_id: int, data: RentalRespondIn
    ) -> RentalOut:
        rental = self.repo.get_by_id(rental_id)
        if rental is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rental not found.",
            )

        if rental.owner_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can respond to rental requests.",
            )

        if rental.status != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only respond to pending rentals.",
            )

        new_status = "accepted" if data.accept else "declined"
        self.repo.update(rental, {"status": new_status})

        # Notify renter (gated by rental_status_changes setting)
        settings_repo = SettingsRepository(self.db)
        renter_settings = settings_repo.get_by_user(rental.renter_id)
        if not renter_settings or renter_settings.rental_status_changes:
            notify(
                self.db,
                user_id=rental.renter_id,
                type="rental",
                title=f"Rental {new_status}",
                body=f"Your rental request was {new_status}.",
                reference_id=rental.id,
                reference_type="rental",
            )

        return self._rental_to_out(rental)

    def update_rental_status(
        self, user: User, rental_id: int, data: RentalStatusUpdate
    ) -> RentalOut:
        rental = self.repo.get_by_id(rental_id)
        if rental is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rental not found.",
            )

        if rental.owner_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can update rental status.",
            )

        valid_statuses = ["active", "returned", "cancelled"]
        if data.status not in valid_statuses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status. Must be one of: {valid_statuses}",
            )

        self.repo.update(rental, {"status": data.status})

        # Notify renter of status change (gated by rental_status_changes setting)
        settings_repo = SettingsRepository(self.db)
        renter_settings = settings_repo.get_by_user(rental.renter_id)
        if not renter_settings or renter_settings.rental_status_changes:
            notify(
                self.db,
                user_id=rental.renter_id,
                type="rental_status",
                title=f"Rental {data.status}",
                body=f"Your rental status has been updated to '{data.status}'.",
                reference_id=rental.id,
                reference_type="rental",
            )

        return self._rental_to_out(rental)

    def get_calendar(self, piece_id: int, year: int, month: int) -> RentalCalendarOut:
        blocked = self.repo.get_blocked_dates(piece_id, year, month)
        ranges = [
            BlockedDateRange(
                start_date=r.start_date,
                end_date=r.end_date,
                status=r.status,
            )
            for r in blocked
        ]
        return RentalCalendarOut(piece_id=piece_id, blocked_dates=ranges)
