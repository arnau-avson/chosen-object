from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    email: str = Field(..., min_length=3, max_length=255, description="Email address")
    username: str = Field(..., min_length=3, max_length=50, description="Unique username")
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    role: str = Field("collector", pattern="^(collector|seller)$", description="collector or seller")
    first_name: str = Field("", max_length=100, description="First name")
    last_name: str = Field("", max_length=100, description="Last name")
    city: str = Field("", max_length=100, description="City")
    country: str = Field("", max_length=100, description="Country")


class LoginRequest(BaseModel):
    """El campo `identifier` acepta email o nombre de usuario;
    el backend decide cuál es según si contiene '@'."""
    identifier: str = Field(..., min_length=1, description="Email o nombre de usuario")
    password: str = Field(..., min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Segundos hasta la expiración")
