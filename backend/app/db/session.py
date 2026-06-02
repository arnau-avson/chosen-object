from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator

from ..core.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,   # reconectar si la conexión está caída
    pool_size=10,
    max_overflow=20,
    echo=settings.is_development,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
