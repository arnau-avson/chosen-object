from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.security import hash_password, verify_password, create_access_token
from ..repositories.user_repository import UserRepository
from ..schemas.auth import LoginRequest, RegisterRequest, TokenResponse


class AuthService:
    def __init__(self, db: Session) -> None:
        self.repo = UserRepository(db)

    def register(self, data: RegisterRequest) -> TokenResponse:
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
        expire_minutes = settings.jwt_access_token_expire_minutes
        access_token = create_access_token(
            subject=user.id,
            expires_delta=timedelta(minutes=expire_minutes),
        )
        return TokenResponse(
            access_token=access_token,
            expires_in=expire_minutes * 60,
        )

    def login(self, data: LoginRequest) -> TokenResponse:
        user = self.repo.get_by_identifier(data.identifier.strip())

        # Respuesta idéntica tanto si el usuario no existe como si la contraseña es
        # incorrecta, para no filtrar información sobre qué cuentas existen.
        invalid = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales incorrectas",
        )

        if user is None or not verify_password(data.password, user.hashed_password):
            raise invalid

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cuenta desactivada. Contacta con soporte.",
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
