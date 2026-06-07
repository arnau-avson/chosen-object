from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.rental import (
    RentalCalendarOut,
    RentalCreate,
    RentalOut,
    RentalRespondIn,
    RentalStatusUpdate,
)
from app.services.rental_service import RentalService

router = APIRouter(prefix="/rentals", tags=["rentals"])


@router.post(
    "",
    response_model=RentalOut,
    status_code=201,
    summary="Request a rental",
)
def create_rental(
    data: RentalCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> RentalOut:
    return RentalService(db).create_rental(current_user, data)


@router.get(
    "",
    response_model=list[RentalOut],
    summary="List rentals",
)
def list_rentals(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    role: str = Query(default="renter", regex="^(renter|owner)$"),
    status: str | None = None,
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[RentalOut]:
    return RentalService(db).list_rentals(
        current_user, role=role, status_filter=status, offset=offset, limit=limit
    )


@router.get(
    "/calendar/{piece_id}",
    response_model=RentalCalendarOut,
    summary="Get rental calendar for a piece",
)
def get_rental_calendar(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    year: int = Query(...),
    month: int = Query(..., ge=1, le=12),
) -> RentalCalendarOut:
    return RentalService(db).get_calendar(piece_id, year, month)


@router.get(
    "/{rental_id}",
    response_model=RentalOut,
    summary="Get rental detail",
)
def get_rental(
    rental_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> RentalOut:
    return RentalService(db).get_rental(current_user, rental_id)


@router.patch(
    "/{rental_id}/respond",
    response_model=RentalOut,
    summary="Accept or decline rental request (owner)",
)
def respond_to_rental(
    rental_id: int,
    data: RentalRespondIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> RentalOut:
    return RentalService(db).respond_to_rental(current_user, rental_id, data)


@router.patch(
    "/{rental_id}/status",
    response_model=RentalOut,
    summary="Update rental status (owner)",
)
def update_rental_status(
    rental_id: int,
    data: RentalStatusUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> RentalOut:
    return RentalService(db).update_rental_status(current_user, rental_id, data)
