from fastapi import APIRouter

from .endpoints import addresses, auth, pieces, profile

router = APIRouter(prefix="/api/v1")

router.include_router(auth.router)
router.include_router(profile.router)
router.include_router(addresses.router)
router.include_router(pieces.router)
