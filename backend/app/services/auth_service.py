from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..core.config import settings
from ..core.security import verify_password, create_access_token
from ..repositories.user_repository import UserRepository
from ..schemas.auth import LoginRequest, TokenResponse


class AuthService:
    def __init__(self, db: Session) -> None:
        self.repo = UserRepository(db)

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
