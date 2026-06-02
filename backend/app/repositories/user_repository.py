from sqlalchemy.orm import Session

from ..models.user import User


class UserRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    # ── Consultas ────────────────────────────────────────────

    def get_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()

    def get_by_email(self, email: str) -> User | None:
        return self.db.query(User).filter(User.email == email.lower()).first()

    def get_by_username(self, username: str) -> User | None:
        return self.db.query(User).filter(User.username == username.lower()).first()

    def get_by_identifier(self, identifier: str) -> User | None:
        """Resuelve el identificador: si contiene '@' busca por email, si no por username."""
        if "@" in identifier:
            return self.get_by_email(identifier)
        return self.get_by_username(identifier)

    # ── Mutaciones ───────────────────────────────────────────

    def create(self, username: str, email: str, hashed_password: str) -> User:
        user = User(
            username=username.lower(),
            email=email.lower(),
            hashed_password=hashed_password,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
