from fastapi import APIRouter

from .endpoints import addresses, auth, profile

router = APIRouter(prefix="/api/v1")

router.include_router(auth.router)
router.include_router(profile.router)
router.include_router(addresses.router)
