from sqlalchemy.orm import Session

from ..models.address import Address


class AddressRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_user(self, user_id: int) -> list[Address]:
        return (
            self.db.query(Address)
            .filter(Address.user_id == user_id)
            .order_by(Address.is_default.desc(), Address.created_at)
            .all()
        )

    def get_by_id(self, address_id: int, user_id: int) -> Address | None:
        return (
            self.db.query(Address)
            .filter(Address.id == address_id, Address.user_id == user_id)
            .first()
        )

    def create(self, user_id: int, data: dict) -> Address:
        # Auto-set as default if this is the user's first address
        existing_count = (
            self.db.query(Address).filter(Address.user_id == user_id).count()
        )
        address = Address(
            user_id=user_id,
            is_default=existing_count == 0,
            **data,
        )
        self.db.add(address)
        self.db.commit()
        self.db.refresh(address)
        return address

    def update(self, address: Address, data: dict) -> Address:
        for key, value in data.items():
            if hasattr(address, key):
                setattr(address, key, value)
        self.db.commit()
        self.db.refresh(address)
        return address

    def delete(self, address: Address) -> None:
        user_id = address.user_id
        was_default = address.is_default
        self.db.delete(address)
        self.db.commit()

        # If deleted address was default, promote the oldest remaining one
        if was_default:
            first = (
                self.db.query(Address)
                .filter(Address.user_id == user_id)
                .order_by(Address.created_at)
                .first()
            )
            if first is not None:
                first.is_default = True
                self.db.commit()

    def set_default(self, address_id: int, user_id: int) -> Address | None:
        # Unset all defaults for user
        self.db.query(Address).filter(
            Address.user_id == user_id
        ).update({"is_default": False})

        # Set the chosen one
        address = self.get_by_id(address_id, user_id)
        if address is None:
            return None
        address.is_default = True
        self.db.commit()
        self.db.refresh(address)
        return address
