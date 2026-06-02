"""
Crea un usuario en la base de datos.

Uso:
    python scripts/create_user.py --username baarrero --email baarrero@example.com --password Arnau_2004

Ejecutar siempre desde la carpeta raíz del backend:
    cd backend
    .venv\\Scripts\\activate
    python scripts/create_user.py --username baarrero --email baarrero@example.com --password Arnau_2004
"""

import argparse
import sys
import os

# Añadir el directorio raíz del backend al path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.repositories.user_repository import UserRepository


def create_user(username: str, email: str, password: str) -> None:
    db = SessionLocal()
    try:
        repo = UserRepository(db)

        if repo.get_by_username(username):
            print(f"[!] Ya existe un usuario con username '{username}'.")
            return

        if repo.get_by_email(email):
            print(f"[!] Ya existe un usuario con email '{email}'.")
            return

        user = repo.create(
            username=username,
            email=email,
            hashed_password=hash_password(password),
        )
        print(f"[✓] Usuario creado: id={user.id}  username={user.username}  email={user.email}")
    finally:
        db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Crear un usuario en la base de datos")
    parser.add_argument("--username", required=True)
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    create_user(
        username=args.username,
        email=args.email,
        password=args.password,
    )
