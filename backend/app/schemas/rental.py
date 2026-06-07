from datetime import date, datetime

from pydantic import BaseModel


class RentalCreate(BaseModel):
    piece_id: int
    start_date: date
    end_date: date
    notes: str | None = None


class RentalOut(BaseModel):
    id: int
    piece_id: int
    piece_title: str | None = None
    renter_id: int
    renter_username: str | None = None
    owner_id: int
    owner_username: str | None = None
    status: str
    start_date: date
    end_date: date
    daily_rate_cents: int
    total_cents: int
    notes: str | None = None
    created_at: datetime
    updated_at: datetime


class RentalRespondIn(BaseModel):
    accept: bool


class RentalStatusUpdate(BaseModel):
    status: str


class BlockedDateRange(BaseModel):
    start_date: date
    end_date: date
    status: str


class RentalCalendarOut(BaseModel):
    piece_id: int
    blocked_dates: list[BlockedDateRange]
