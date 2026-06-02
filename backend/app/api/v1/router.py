from fastapi import APIRouter

from .endpoints import auth

router = APIRouter(prefix="/api/v1")

router.include_router(auth.router)
