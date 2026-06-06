from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.address import AddressCreate, AddressOut, AddressUpdate
from app.services.address_service import AddressService

router = APIRouter(prefix="/addresses", tags=["addresses"])


@router.get(
    "",
    response_model=list[AddressOut],
    summary="List all addresses for the authenticated user",
)
def list_addresses(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> list[AddressOut]:
    return AddressService(db).list_addresses(current_user)


@router.post(
    "",
    response_model=AddressOut,
    summary="Create a new address",
    status_code=201,
)
def create_address(
    data: AddressCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> AddressOut:
    return AddressService(db).create_address(current_user, data)


@router.put(
    "/{address_id}",
    response_model=AddressOut,
    summary="Update an existing address",
)
def update_address(
    address_id: int,
    data: AddressUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> AddressOut:
    return AddressService(db).update_address(current_user, address_id, data)


@router.delete(
    "/{address_id}",
    status_code=204,
    summary="Delete an address",
)
def delete_address(
    address_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> None:
    AddressService(db).delete_address(current_user, address_id)


@router.patch(
    "/{address_id}/default",
    response_model=AddressOut,
    summary="Set an address as default",
)
def set_default(
    address_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> AddressOut:
    return AddressService(db).set_default(current_user, address_id)
