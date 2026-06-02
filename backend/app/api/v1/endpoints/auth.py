from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    MessageResponse,
    RegisterRequest,
    ResendPinRequest,
    TokenResponse,
    VerifyEmailRequest,
)
from app.schemas.user import UserOut
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=201,
    summary="Create a new account",
)
def register(
    data: RegisterRequest,
    db: Annotated[Session, Depends(get_db)],
) -> MessageResponse:
    return AuthService(db).register(data)


@router.post(
    "/verify-email",
    response_model=TokenResponse,
    summary="Verify email with PIN code",
)
def verify_email(
    data: VerifyEmailRequest,
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    return AuthService(db).verify_email(data)


@router.post(
    "/resend-pin",
    response_model=MessageResponse,
    summary="Resend verification PIN",
)
def resend_pin(
    data: ResendPinRequest,
    db: Annotated[Session, Depends(get_db)],
) -> MessageResponse:
    return AuthService(db).resend_pin(data)


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Sign in",
    description="Accepts email or username in the `identifier` field. Returns a JWT access token.",
)
def login(
    data: LoginRequest,
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    return AuthService(db).login(data)


@router.get(
    "/me",
    response_model=UserOut,
    summary="Authenticated user profile",
)
def me(current_user: Annotated[User, Depends(get_current_user)]) -> User:
    return current_user
