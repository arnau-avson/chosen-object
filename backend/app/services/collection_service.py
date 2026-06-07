from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.collection_repository import CollectionRepository
from ..schemas.collection import (
    CollectionCreate,
    CollectionDetailOut,
    CollectionOut,
    SavedPieceOut,
)


class CollectionService:
    def __init__(self, db: Session) -> None:
        self.repo = CollectionRepository(db)

    # ── Saves ─────────────────────────────────────────────────

    def toggle_save(self, user: User, piece_id: int) -> dict:
        piece = self.repo.get_piece(piece_id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )

        existing = self.repo.get_save(user.id, piece_id)
        if existing:
            self.repo.delete_save(existing)
            return {"saved": False}
        else:
            self.repo.create_save(user.id, piece_id)
            return {"saved": True}

    def get_saved_pieces(
        self, user: User, offset: int = 0, limit: int = 20
    ) -> list[SavedPieceOut]:
        results = self.repo.get_saved_pieces(user.id, offset, limit)
        return [
            SavedPieceOut.from_piece(piece, saved_at=save.created_at)
            for piece, save in results
        ]

    # ── Collections ───────────────────────────────────────────

    def create_collection(self, user: User, data: CollectionCreate) -> CollectionOut:
        collection = self.repo.create_collection(user.id, data.name)
        return CollectionOut.from_model(collection)

    def list_collections(self, user: User) -> list[CollectionOut]:
        collections = self.repo.get_collections(user.id)
        return [CollectionOut.from_model(c) for c in collections]

    def get_collection_detail(
        self, user: User, collection_id: int
    ) -> CollectionDetailOut:
        collection = self.repo.get_collection_by_id(collection_id, user.id)
        if collection is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Collection not found.",
            )

        pieces_data = self.repo.get_collection_pieces(collection_id)
        pieces = [
            SavedPieceOut.from_piece(piece, saved_at=cp.added_at)
            for piece, cp in pieces_data
        ]

        return CollectionDetailOut(
            id=collection.id,
            name=collection.name,
            piece_count=len(pieces),
            created_at=collection.created_at,
            pieces=pieces,
        )

    def rename_collection(
        self, user: User, collection_id: int, name: str
    ) -> CollectionOut:
        collection = self.repo.get_collection_by_id(collection_id, user.id)
        if collection is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Collection not found.",
            )
        collection = self.repo.update_collection(collection, name)
        return CollectionOut.from_model(collection)

    def delete_collection(self, user: User, collection_id: int) -> None:
        collection = self.repo.get_collection_by_id(collection_id, user.id)
        if collection is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Collection not found.",
            )
        self.repo.delete_collection(collection)

    def add_piece_to_collection(
        self, user: User, collection_id: int, piece_id: int
    ) -> dict:
        collection = self.repo.get_collection_by_id(collection_id, user.id)
        if collection is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Collection not found.",
            )

        piece = self.repo.get_piece(piece_id)
        if piece is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not found.",
            )

        try:
            self.repo.add_piece_to_collection(collection_id, piece_id)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Piece already in collection.",
            )
        return {"added": True}

    def remove_piece_from_collection(
        self, user: User, collection_id: int, piece_id: int
    ) -> dict:
        collection = self.repo.get_collection_by_id(collection_id, user.id)
        if collection is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Collection not found.",
            )

        removed = self.repo.remove_piece_from_collection(collection_id, piece_id)
        if not removed:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Piece not in collection.",
            )
        return {"removed": True}
