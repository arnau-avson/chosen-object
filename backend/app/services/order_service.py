import base64
from collections import defaultdict

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.order_repository import OrderRepository
from ..schemas.order import OrderCreate, OrderItemOut, OrderOut, OrderStatusUpdate
from .notification_helper import notify


class OrderService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = OrderRepository(db)

    def create_orders_from_cart(
        self, user: User, data: OrderCreate
    ) -> list[OrderOut]:
        cart_data = self.repo.get_cart_items_with_pieces(user.id)
        if not cart_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cart is empty.",
            )

        # Group cart items by seller
        by_seller: dict[int, list] = defaultdict(list)
        for cart_item, piece in cart_data:
            if piece.stock <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"'{piece.title}' is out of stock.",
                )
            by_seller[piece.user_id].append((cart_item, piece))

        created_orders = []

        for seller_id, items in by_seller.items():
            total = sum(piece.price_cents for _, piece in items)
            order = self.repo.create_order(
                buyer_id=user.id,
                seller_id=seller_id,
                total_cents=total,
                shipping_address_id=data.shipping_address_id,
                notes=data.notes,
            )

            for _, piece in items:
                self.repo.create_order_item(
                    order_id=order.id,
                    piece_id=piece.id,
                    price_cents=piece.price_cents,
                )
                self.repo.decrement_stock(piece)

            created_orders.append((order, items, seller_id))

        # Clear cart and commit all changes
        self.repo.clear_cart(user.id)
        self.repo.commit()

        # Build response and send notifications
        results = []
        for order, items, seller_id in created_orders:
            order_items = []
            for _, piece in items:
                cover_b64 = None
                if piece.images:
                    first = min(piece.images, key=lambda img: img.position)
                    cover_b64 = base64.b64encode(first.image_data).decode("ascii")
                order_items.append(
                    OrderItemOut(
                        id=0,
                        piece_id=piece.id,
                        piece_title=piece.title,
                        piece_cover_b64=cover_b64,
                        price_cents=piece.price_cents,
                        quantity=1,
                    )
                )

            seller = self.repo.get_user_by_id(seller_id)
            results.append(
                OrderOut(
                    id=order.id,
                    buyer_id=order.buyer_id,
                    seller_id=order.seller_id,
                    status=order.status,
                    total_cents=order.total_cents,
                    shipping_address_id=order.shipping_address_id,
                    tracking_number=order.tracking_number,
                    notes=order.notes,
                    items=order_items,
                    created_at=order.created_at,
                    updated_at=order.updated_at,
                    buyer_username=user.username,
                    seller_username=seller.username if seller else None,
                )
            )

            # Notify seller
            notify(
                self.db,
                user_id=seller_id,
                type="order",
                title="New order received",
                body=f"{user.username} placed an order.",
                reference_id=order.id,
                reference_type="order",
            )

        return results

    def list_orders(
        self,
        user: User,
        role: str = "buyer",
        status_filter: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[OrderOut]:
        orders = self.repo.get_orders(user.id, role, status_filter, offset, limit)
        results = []
        for order in orders:
            buyer = self.repo.get_user_by_id(order.buyer_id)
            seller = self.repo.get_user_by_id(order.seller_id)

            order_items = []
            for item in order.items:
                piece = self.repo.get_piece_by_id(item.piece_id)
                cover_b64 = None
                title = None
                if piece:
                    title = piece.title
                    if piece.images:
                        first = min(piece.images, key=lambda img: img.position)
                        cover_b64 = base64.b64encode(first.image_data).decode("ascii")
                order_items.append(
                    OrderItemOut(
                        id=item.id,
                        piece_id=item.piece_id,
                        piece_title=title,
                        piece_cover_b64=cover_b64,
                        price_cents=item.price_cents,
                        quantity=item.quantity,
                    )
                )

            results.append(
                OrderOut(
                    id=order.id,
                    buyer_id=order.buyer_id,
                    seller_id=order.seller_id,
                    status=order.status,
                    total_cents=order.total_cents,
                    shipping_address_id=order.shipping_address_id,
                    tracking_number=order.tracking_number,
                    notes=order.notes,
                    items=order_items,
                    created_at=order.created_at,
                    updated_at=order.updated_at,
                    buyer_username=buyer.username if buyer else None,
                    seller_username=seller.username if seller else None,
                )
            )
        return results

    def get_order(self, user: User, order_id: int) -> OrderOut:
        order = self.repo.get_order_by_id(order_id)
        if order is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )

        if order.buyer_id != user.id and order.seller_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view this order.",
            )

        buyer = self.repo.get_user_by_id(order.buyer_id)
        seller = self.repo.get_user_by_id(order.seller_id)

        order_items = []
        for item in order.items:
            piece = self.repo.get_piece_by_id(item.piece_id)
            cover_b64 = None
            title = None
            if piece:
                title = piece.title
                if piece.images:
                    first = min(piece.images, key=lambda img: img.position)
                    cover_b64 = base64.b64encode(first.image_data).decode("ascii")
            order_items.append(
                OrderItemOut(
                    id=item.id,
                    piece_id=item.piece_id,
                    piece_title=title,
                    piece_cover_b64=cover_b64,
                    price_cents=item.price_cents,
                    quantity=item.quantity,
                )
            )

        return OrderOut(
            id=order.id,
            buyer_id=order.buyer_id,
            seller_id=order.seller_id,
            status=order.status,
            total_cents=order.total_cents,
            shipping_address_id=order.shipping_address_id,
            tracking_number=order.tracking_number,
            notes=order.notes,
            items=order_items,
            created_at=order.created_at,
            updated_at=order.updated_at,
            buyer_username=buyer.username if buyer else None,
            seller_username=seller.username if seller else None,
        )

    def update_order_status(
        self, user: User, order_id: int, data: OrderStatusUpdate
    ) -> OrderOut:
        order = self.repo.get_order_by_id(order_id)
        if order is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )

        if order.seller_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the seller can update order status.",
            )

        valid_statuses = ["pending", "confirmed", "shipped", "delivered", "cancelled"]
        if data.status not in valid_statuses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status. Must be one of: {valid_statuses}",
            )

        updates = {"status": data.status}
        if data.tracking_number is not None:
            updates["tracking_number"] = data.tracking_number

        self.repo.update_order(order, updates)

        # Notify buyer
        notify(
            self.db,
            user_id=order.buyer_id,
            type="order",
            title="Order updated",
            body=f"Your order #{order.id} status changed to {data.status}.",
            reference_id=order.id,
            reference_type="order",
        )

        return self.get_order(user, order_id)

    def cancel_order(self, user: User, order_id: int) -> OrderOut:
        order = self.repo.get_order_by_id(order_id)
        if order is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found.",
            )

        if order.buyer_id != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the buyer can cancel an order.",
            )

        if order.status != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only cancel pending orders.",
            )

        self.repo.update_order(order, {"status": "cancelled"})

        # Restore stock
        for item in order.items:
            piece = self.repo.get_piece_by_id(item.piece_id)
            if piece:
                piece.stock += item.quantity
                self.db.commit()

        # Notify seller
        notify(
            self.db,
            user_id=order.seller_id,
            type="order",
            title="Order cancelled",
            body=f"Order #{order.id} was cancelled by the buyer.",
            reference_id=order.id,
            reference_type="order",
        )

        return self.get_order(user, order_id)
