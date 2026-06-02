from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, TokenResponse
from app.schemas.user import UserOut
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Iniciar sesión",
    description=(
        "Acepta email **o** nombre de usuario en el campo `identifier`. "
        "Devuelve un JWT de acceso."
    ),
)
def login(
    data: LoginRequest,
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    return AuthService(db).login(data)


@router.get(
    "/me",
    response_model=UserOut,
    summary="Perfil del usuario autenticado",
)
def me(current_user: Annotated[User, Depends(get_current_user)]) -> User:
    return current_user
