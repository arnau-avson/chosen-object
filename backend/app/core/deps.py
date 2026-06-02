from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from sqlalchemy.orm import Session

from .security import decode_token
from ..db.session import get_db
from ..repositories.user_repository import UserRepository
from ..models.user import User

bearer_scheme = HTTPBearer(auto_error=True)


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(credentials.credentials)
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise unauthorized
    except JWTError:
        raise unauthorized

    user = UserRepository(db).get_by_id(int(user_id))
    if user is None or not user.is_active:
        raise unauthorized
    return user
