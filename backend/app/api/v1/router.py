from fastapi import APIRouter

from .endpoints import (
    addresses,
    auth,
    browse,
    cart,
    collections,
    dashboard,
    device_tokens,
    follows,
    messages,
    notifications,
    orders,
    pieces,
    profile,
    rentals,
    settings,
    websocket,
)

router = APIRouter(prefix="/api/v1")

router.include_router(auth.router)
router.include_router(profile.router)
router.include_router(addresses.router)
router.include_router(pieces.router)
router.include_router(browse.router)
router.include_router(follows.router)
router.include_router(settings.router)
router.include_router(collections.router)
router.include_router(cart.router)
router.include_router(orders.router)
router.include_router(rentals.router)
router.include_router(messages.router)
router.include_router(notifications.router)
router.include_router(dashboard.router)
router.include_router(device_tokens.router)
router.include_router(websocket.router)
