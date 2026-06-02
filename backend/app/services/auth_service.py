import random
import string
from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.security import hash_password, verify_password, create_access_token
from ..repositories.user_repository import UserRepository
from ..schemas.auth import (
    LoginRequest,
    RegisterRequest,
    ResendPinRequest,
    TokenResponse,
    VerifyEmailRequest,
    MessageResponse,
)


def _generate_pin() -> str:
    return "".join(random.choices(string.digits, k=6))


class AuthService:
    def __init__(self, db: Session) -> None:
        self.repo = UserRepository(db)

    # ── Register ───────────────────────────────────────────────

    def register(self, data: RegisterRequest) -> MessageResponse:
        if self.repo.get_by_email(data.email.strip()):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists.",
            )
        if self.repo.get_by_username(data.username.strip()):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="This username is already taken.",
            )

        pin = _generate_pin()
        user = self.repo.create(
            username=data.username.strip(),
            email=data.email.strip(),
            hashed_password=hash_password(data.password),
            role=data.role,
            first_name=data.first_name.strip(),
            last_name=data.last_name.strip(),
            city=data.city.strip(),
            country=data.country.strip(),
        )
        self.repo.set_verification_pin(user, pin)
        # TODO: send verification email with pin
        return MessageResponse(message="Account created. Please verify your email.")

    # ── Verify email ───────────────────────────────────────────

    def verify_email(self, data: VerifyEmailRequest) -> TokenResponse:
        user = self.repo.get_by_email(data.email.strip())
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Account not found.",
            )
        if user.email_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is already verified.",
            )
        if user.verification_pin != data.pin:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code.",
            )

        self.repo.verify_email(user)

        expire_minutes = settings.jwt_access_token_expire_minutes
        access_token = create_access_token(
            subject=user.id,
            expires_delta=timedelta(minutes=expire_minutes),
        )
        return TokenResponse(
            access_token=access_token,
            expires_in=expire_minutes * 60,
        )

    # ── Resend PIN ─────────────────────────────────────────────

    def resend_pin(self, data: ResendPinRequest) -> MessageResponse:
        user = self.repo.get_by_email(data.email.strip())
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Account not found.",
            )
        if user.email_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is already verified.",
            )

        pin = _generate_pin()
        self.repo.set_verification_pin(user, pin)
        # TODO: send verification email with pin
        return MessageResponse(message="A new verification code has been generated.")

    # ── Login ──────────────────────────────────────────────────

    def login(self, data: LoginRequest) -> TokenResponse:
        user = self.repo.get_by_identifier(data.identifier.strip())

        if user is None or not verify_password(data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email/username or password.",
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account disabled. Contact support.",
            )

        if not user.email_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email not verified.",
            )

        expire_minutes = settings.jwt_access_token_expire_minutes
        access_token = create_access_token(
            subject=user.id,
            expires_delta=timedelta(minutes=expire_minutes),
        )

        return TokenResponse(
            access_token=access_token,
            expires_in=expire_minutes * 60,
        )
