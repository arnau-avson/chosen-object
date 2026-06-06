from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models.user import User
from ..repositories.address_repository import AddressRepository
from ..schemas.address import AddressCreate, AddressOut, AddressUpdate


class AddressService:
    def __init__(self, db: Session) -> None:
        self.repo = AddressRepository(db)

    def list_addresses(self, user: User) -> list[AddressOut]:
        addresses = self.repo.get_by_user(user.id)
        return [AddressOut.model_validate(a) for a in addresses]

    def create_address(self, user: User, data: AddressCreate) -> AddressOut:
        address = self.repo.create(user.id, data.model_dump())
        return AddressOut.model_validate(address)

    def update_address(
        self, user: User, address_id: int, data: AddressUpdate
    ) -> AddressOut:
        address = self.repo.get_by_id(address_id, user.id)
        if address is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )
        fields = data.model_dump(exclude_unset=True)
        if not fields:
            return AddressOut.model_validate(address)
        address = self.repo.update(address, fields)
        return AddressOut.model_validate(address)

    def delete_address(self, user: User, address_id: int) -> None:
        address = self.repo.get_by_id(address_id, user.id)
        if address is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )
        self.repo.delete(address)

    def set_default(self, user: User, address_id: int) -> AddressOut:
        address = self.repo.set_default(address_id, user.id)
        if address is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found.",
            )
        return AddressOut.model_validate(address)
