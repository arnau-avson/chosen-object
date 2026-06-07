from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.cart_repository import CartRepository
from ..schemas.cart import CartItemOut, CartOut


class CartService:
    def __init__(self, db: Session) -> None:
        self.repo = CartRepository(db)

    def add_to_cart(self, user: User, piece_id: int) -> dict:
        piece = self.repo.get_piece(piece_id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found or not available.",
            )

        if piece.user_id == user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot add your own piece to cart.",
            )

        if piece.stock <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Piece is out of stock.",
            )

        existing = self.repo.get_cart_item(user.id, piece_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Piece already in cart.",
            )

        self.repo.add_item(user.id, piece_id)
        return {"added": True}

    def remove_from_cart(self, user: User, piece_id: int) -> dict:
        item = self.repo.get_cart_item(user.id, piece_id)
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not in cart.",
            )
        self.repo.remove_item(item)
        return {"removed": True}

    def get_cart(self, user: User) -> CartOut:
        results = self.repo.get_cart_items(user.id)
        items = []
        total = 0
        for cart_item, piece, seller in results:
            items.append(
                CartItemOut.from_piece(
                    piece,
                    added_at=cart_item.added_at,
                    seller_username=seller.username,
                )
            )
            total += piece.price_cents

        return CartOut(
            items=items,
            item_count=len(items),
            total_cents=total,
        )

    def clear_cart(self, user: User) -> dict:
        self.repo.clear_cart(user.id)
        return {"cleared": True}
