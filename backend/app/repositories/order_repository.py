from sqlalchemy.orm import Session, joinedload

from ..models.cart import CartItem
from ..models.order import Order, OrderItem
from ..models.piece import Piece
from ..models.user import User


class OrderRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_cart_items_with_pieces(
        self, user_id: int
    ) -> list[tuple[CartItem, Piece]]:
        return (
            self.db.query(CartItem, Piece)
            .join(Piece, CartItem.piece_id == Piece.id)
            .options(joinedload(Piece.images))
            .filter(CartItem.user_id == user_id)
            .all()
        )

    def create_order(
        self,
        buyer_id: int,
        seller_id: int,
        total_cents: int,
        shipping_address_id: int | None = None,
        notes: str | None = None,
    ) -> Order:
        order = Order(
            buyer_id=buyer_id,
            seller_id=seller_id,
            total_cents=total_cents,
            shipping_address_id=shipping_address_id,
            notes=notes,
        )
        self.db.add(order)
        self.db.flush()
        return order

    def create_order_item(
        self, order_id: int, piece_id: int, price_cents: int, quantity: int = 1
    ) -> OrderItem:
        item = OrderItem(
            order_id=order_id,
            piece_id=piece_id,
            price_cents=price_cents,
            quantity=quantity,
        )
        self.db.add(item)
        return item

    def decrement_stock(self, piece: Piece, quantity: int = 1) -> None:
        piece.stock = max(0, piece.stock - quantity)

    def clear_cart(self, user_id: int) -> None:
        self.db.query(CartItem).filter(CartItem.user_id == user_id).delete()

    def commit(self) -> None:
        self.db.commit()

    def get_orders(
        self,
        user_id: int,
        role: str = "buyer",
        status_filter: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[Order]:
        q = self.db.query(Order).options(joinedload(Order.items))

        if role == "seller":
            q = q.filter(Order.seller_id == user_id)
        else:
            q = q.filter(Order.buyer_id == user_id)

        if status_filter:
            q = q.filter(Order.status == status_filter)

        return q.order_by(Order.created_at.desc()).offset(offset).limit(limit).all()

    def get_order_by_id(self, order_id: int) -> Order | None:
        return (
            self.db.query(Order)
            .options(joinedload(Order.items))
            .filter(Order.id == order_id)
            .first()
        )

    def get_user_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()

    def get_piece_by_id(self, piece_id: int) -> Piece | None:
        return (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.id == piece_id)
            .first()
        )

    def update_order(self, order: Order, data: dict) -> Order:
        for key, value in data.items():
            setattr(order, key, value)
        self.db.commit()
        self.db.refresh(order)
        return order
