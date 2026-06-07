from sqlalchemy.orm import Session, joinedload

from ..models.cart import CartItem
from ..models.piece import Piece
from ..models.user import User


class CartRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_cart_items(self, user_id: int) -> list[tuple[CartItem, Piece, User]]:
        results = (
            self.db.query(CartItem, Piece, User)
            .join(Piece, CartItem.piece_id == Piece.id)
            .join(User, Piece.user_id == User.id)
            .options(joinedload(Piece.images))
            .filter(CartItem.user_id == user_id)
            .order_by(CartItem.added_at.desc())
            .all()
        )
        return results

    def get_cart_item(self, user_id: int, piece_id: int) -> CartItem | None:
        return (
            self.db.query(CartItem)
            .filter(CartItem.user_id == user_id, CartItem.piece_id == piece_id)
            .first()
        )

    def add_item(self, user_id: int, piece_id: int) -> CartItem:
        item = CartItem(user_id=user_id, piece_id=piece_id)
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def remove_item(self, item: CartItem) -> None:
        self.db.delete(item)
        self.db.commit()

    def clear_cart(self, user_id: int) -> None:
        self.db.query(CartItem).filter(CartItem.user_id == user_id).delete()
        self.db.commit()

    def get_piece(self, piece_id: int) -> Piece | None:
        return (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.id == piece_id, Piece.status == "active")
            .first()
        )
