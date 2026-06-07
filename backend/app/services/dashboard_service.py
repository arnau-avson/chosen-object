from datetime import datetime, timedelta, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session

from ..models.order import Order, OrderItem
from ..models.piece import Piece
from ..models.rental import Rental
from ..models.user import User
from ..schemas.dashboard import DashboardOut, RecentSaleOut, TopPieceOut


class DashboardService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_dashboard(self, user: User, range_filter: str = "all") -> DashboardOut:
        since = self._get_since(range_filter)

        # Orders where user is seller
        order_query = self.db.query(Order).filter(
            Order.seller_id == user.id,
            Order.status != "cancelled",
        )
        if since:
            order_query = order_query.filter(Order.created_at >= since)

        orders = order_query.all()
        total_revenue = sum(o.total_cents for o in orders)
        order_count = len(orders)

        # Rentals where user is owner
        rental_query = self.db.query(Rental).filter(
            Rental.owner_id == user.id,
            Rental.status.in_(["accepted", "active", "returned"]),
        )
        if since:
            rental_query = rental_query.filter(Rental.created_at >= since)

        rentals = rental_query.all()
        rental_revenue = sum(r.total_cents for r in rentals)
        rental_count = len(rentals)

        # Top pieces by revenue
        top_pieces_query = (
            self.db.query(
                OrderItem.piece_id,
                Piece.title,
                func.sum(OrderItem.price_cents * OrderItem.quantity).label("revenue"),
                func.count(OrderItem.id).label("count"),
            )
            .join(Order, OrderItem.order_id == Order.id)
            .join(Piece, OrderItem.piece_id == Piece.id)
            .filter(Order.seller_id == user.id, Order.status != "cancelled")
        )
        if since:
            top_pieces_query = top_pieces_query.filter(Order.created_at >= since)

        top_pieces_data = (
            top_pieces_query.group_by(OrderItem.piece_id, Piece.title)
            .order_by(func.sum(OrderItem.price_cents * OrderItem.quantity).desc())
            .limit(5)
            .all()
        )

        top_pieces = [
            TopPieceOut(
                piece_id=row[0],
                title=row[1] or "Unknown",
                revenue_cents=int(row[2] or 0),
                order_count=int(row[3] or 0),
            )
            for row in top_pieces_data
        ]

        # Recent sales
        recent_orders = (
            self.db.query(Order)
            .filter(Order.seller_id == user.id)
            .order_by(Order.created_at.desc())
            .limit(10)
            .all()
        )

        recent_sales = []
        for o in recent_orders:
            buyer = self.db.query(User).filter(User.id == o.buyer_id).first()
            recent_sales.append(
                RecentSaleOut(
                    order_id=o.id,
                    buyer_username=buyer.username if buyer else None,
                    total_cents=o.total_cents,
                    status=o.status,
                    created_at=o.created_at.isoformat() if o.created_at else "",
                )
            )

        return DashboardOut(
            total_revenue_cents=total_revenue,
            order_count=order_count,
            rental_revenue_cents=rental_revenue,
            rental_count=rental_count,
            top_pieces=top_pieces,
            recent_sales=recent_sales,
        )

    def _get_since(self, range_filter: str) -> datetime | None:
        now = datetime.now(timezone.utc)
        if range_filter == "day":
            return now - timedelta(days=1)
        elif range_filter == "week":
            return now - timedelta(weeks=1)
        elif range_filter == "month":
            return now - timedelta(days=30)
        elif range_filter == "year":
            return now - timedelta(days=365)
        return None  # "all"
