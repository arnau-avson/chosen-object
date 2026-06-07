from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.order import OrderCreate, OrderOut, OrderStatusUpdate
from app.services.order_service import OrderService

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post(
    "",
    response_model=list[OrderOut],
    status_code=201,
    summary="Create orders from cart",
)
def create_orders(
    data: OrderCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[OrderOut]:
    return OrderService(db).create_orders_from_cart(current_user, data)


@router.get(
    "",
    response_model=list[OrderOut],
    summary="List orders",
)
def list_orders(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    role: str = Query(default="buyer", regex="^(buyer|seller)$"),
    status: str | None = None,
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[OrderOut]:
    return OrderService(db).list_orders(
        current_user, role=role, status_filter=status, offset=offset, limit=limit
    )


@router.get(
    "/{order_id}",
    response_model=OrderOut,
    summary="Get order detail",
)
def get_order(
    order_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> OrderOut:
    return OrderService(db).get_order(current_user, order_id)


@router.patch(
    "/{order_id}/status",
    response_model=OrderOut,
    summary="Update order status (seller)",
)
def update_order_status(
    order_id: int,
    data: OrderStatusUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> OrderOut:
    return OrderService(db).update_order_status(current_user, order_id, data)


@router.post(
    "/{order_id}/cancel",
    response_model=OrderOut,
    summary="Cancel order (buyer, only if pending)",
)
def cancel_order(
    order_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> OrderOut:
    return OrderService(db).cancel_order(current_user, order_id)
