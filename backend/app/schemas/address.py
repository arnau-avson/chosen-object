from pydantic import BaseModel


class AddressOut(BaseModel):
    id: int
    label: str
    full_name: str
    street: str
    number: str
    details: str | None = None
    city: str
    postal_code: str
    country: str
    phone: str
    is_default: bool = False

    model_config = {"from_attributes": True}


class AddressCreate(BaseModel):
    label: str
    full_name: str
    street: str
    number: str
    details: str | None = None
    city: str
    postal_code: str
    country: str
    phone: str


class AddressUpdate(BaseModel):
    label: str | None = None
    full_name: str | None = None
    street: str | None = None
    number: str | None = None
    details: str | None = None
    city: str | None = None
    postal_code: str | None = None
    country: str | None = None
    phone: str | None = None
