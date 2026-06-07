from sqlalchemy.orm import Session, joinedload

from ..models.collection import Collection, CollectionPiece, Save
from ..models.piece import Piece


class CollectionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    # ── Saves ─────────────────────────────────────────────────

    def get_save(self, user_id: int, piece_id: int) -> Save | None:
        return (
            self.db.query(Save)
            .filter(Save.user_id == user_id, Save.piece_id == piece_id)
            .first()
        )

    def create_save(self, user_id: int, piece_id: int) -> Save:
        save = Save(user_id=user_id, piece_id=piece_id)
        self.db.add(save)
        self.db.commit()
        self.db.refresh(save)
        return save

    def delete_save(self, save: Save) -> None:
        self.db.delete(save)
        self.db.commit()

    def get_saved_pieces(
        self, user_id: int, offset: int = 0, limit: int = 20
    ) -> list[tuple[Piece, Save]]:
        results = (
            self.db.query(Piece, Save)
            .join(Save, Save.piece_id == Piece.id)
            .options(joinedload(Piece.images))
            .filter(Save.user_id == user_id)
            .order_by(Save.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return results

    # ── Collections ───────────────────────────────────────────

    def get_collections(self, user_id: int) -> list[Collection]:
        return (
            self.db.query(Collection)
            .options(joinedload(Collection.pieces))
            .filter(Collection.user_id == user_id)
            .order_by(Collection.created_at.desc())
            .all()
        )

    def get_collection_by_id(
        self, collection_id: int, user_id: int
    ) -> Collection | None:
        return (
            self.db.query(Collection)
            .options(joinedload(Collection.pieces))
            .filter(Collection.id == collection_id, Collection.user_id == user_id)
            .first()
        )

    def create_collection(self, user_id: int, name: str) -> Collection:
        collection = Collection(user_id=user_id, name=name)
        self.db.add(collection)
        self.db.commit()
        self.db.refresh(collection)
        return collection

    def update_collection(self, collection: Collection, name: str) -> Collection:
        collection.name = name
        self.db.commit()
        self.db.refresh(collection)
        return collection

    def delete_collection(self, collection: Collection) -> None:
        self.db.delete(collection)
        self.db.commit()

    def add_piece_to_collection(
        self, collection_id: int, piece_id: int
    ) -> CollectionPiece:
        cp = CollectionPiece(collection_id=collection_id, piece_id=piece_id)
        self.db.add(cp)
        self.db.commit()
        self.db.refresh(cp)
        return cp

    def remove_piece_from_collection(
        self, collection_id: int, piece_id: int
    ) -> bool:
        cp = (
            self.db.query(CollectionPiece)
            .filter(
                CollectionPiece.collection_id == collection_id,
                CollectionPiece.piece_id == piece_id,
            )
            .first()
        )
        if cp is None:
            return False
        self.db.delete(cp)
        self.db.commit()
        return True

    def get_collection_pieces(
        self, collection_id: int
    ) -> list[tuple[Piece, CollectionPiece]]:
        return (
            self.db.query(Piece, CollectionPiece)
            .join(CollectionPiece, CollectionPiece.piece_id == Piece.id)
            .options(joinedload(Piece.images))
            .filter(CollectionPiece.collection_id == collection_id)
            .order_by(CollectionPiece.added_at.desc())
            .all()
        )

    def get_piece(self, piece_id: int) -> Piece | None:
        return self.db.query(Piece).filter(Piece.id == piece_id).first()
