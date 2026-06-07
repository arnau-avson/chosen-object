import json

from sqlalchemy.orm import Session, joinedload

from ..models.piece import Piece, PieceImage


class PieceRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_user(self, user_id: int) -> list[Piece]:
        return (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.user_id == user_id)
            .order_by(Piece.created_at.desc())
            .all()
        )

    def get_by_id(self, piece_id: int, user_id: int) -> Piece | None:
        return (
            self.db.query(Piece)
            .options(joinedload(Piece.images))
            .filter(Piece.id == piece_id, Piece.user_id == user_id)
            .first()
        )

    def create(self, user_id: int, data: dict) -> Piece:
        ships_to = data.pop("ships_to", None)
        piece = Piece(
            user_id=user_id,
            ships_to=json.dumps(ships_to) if ships_to else None,
            **data,
        )
        self.db.add(piece)
        self.db.commit()
        self.db.refresh(piece)
        return piece

    def add_image(
        self, piece_id: int, position: int, image_data: bytes
    ) -> PieceImage:
        img = PieceImage(
            piece_id=piece_id,
            position=position,
            image_data=image_data,
        )
        self.db.add(img)
        self.db.commit()
        self.db.refresh(img)
        return img

    def update(self, piece: Piece, data: dict) -> Piece:
        ships_to = data.pop("ships_to", None)
        if ships_to is not None:
            piece.ships_to = json.dumps(ships_to) if ships_to else None
        for key, value in data.items():
            setattr(piece, key, value)
        self.db.commit()
        self.db.refresh(piece)
        return piece

    def get_image(self, image_id: int, piece_id: int) -> PieceImage | None:
        return (
            self.db.query(PieceImage)
            .filter(PieceImage.id == image_id, PieceImage.piece_id == piece_id)
            .first()
        )

    def delete_image(self, image: PieceImage) -> None:
        self.db.delete(image)
        self.db.commit()

    def delete(self, piece: Piece) -> None:
        self.db.delete(piece)
        self.db.commit()
