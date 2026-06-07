import base64
from datetime import datetime

from pydantic import BaseModel

from ..models.order import Order, OrderItem
from ..models.piece import Piece


class OrderItemOut(BaseModel):
    id: int
    piece_id: int
    piece_title: str | None = None
    piece_cover_b64: str | None = None
    price_cents: int
    quantity: int


class OrderOut(BaseModel):
    id: int
    buyer_id: int
    seller_id: int
    status: str
    total_cents: int
    shipping_address_id: int | None = None
    tracking_number: str | None = None
    notes: str | None = None
    items: list[OrderItemOut] = []
    created_at: datetime
    updated_at: datetime
    buyer_username: str | None = None
    seller_username: str | None = None


class OrderCreate(BaseModel):
    shipping_address_id: int | None = None
    notes: str | None = None


class OrderStatusUpdate(BaseModel):
    status: str
    tracking_number: str | None = None
