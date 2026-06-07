from pydantic import BaseModel


class TopPieceOut(BaseModel):
    piece_id: int
    title: str
    revenue_cents: int
    order_count: int


class RecentSaleOut(BaseModel):
    order_id: int
    buyer_username: str | None = None
    total_cents: int
    status: str
    created_at: str


class DashboardOut(BaseModel):
    total_revenue_cents: int = 0
    order_count: int = 0
    rental_revenue_cents: int = 0
    rental_count: int = 0
    top_pieces: list[TopPieceOut] = []
    recent_sales: list[RecentSaleOut] = []
