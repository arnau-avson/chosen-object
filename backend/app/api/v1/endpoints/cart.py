from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.cart import CartOut
from app.services.cart_service import CartService

router = APIRouter(prefix="/cart", tags=["cart"])


@router.post(
    "/{piece_id}",
    summary="Add piece to cart",
)
def add_to_cart(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return CartService(db).add_to_cart(current_user, piece_id)


@router.delete(
    "/{piece_id}",
    summary="Remove piece from cart",
)
def remove_from_cart(
    piece_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return CartService(db).remove_from_cart(current_user, piece_id)


@router.get(
    "",
    response_model=CartOut,
    summary="View cart",
)
def get_cart(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CartOut:
    return CartService(db).get_cart(current_user)


@router.delete(
    "",
    summary="Clear cart",
)
def clear_cart(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    return CartService(db).clear_cart(current_user)
