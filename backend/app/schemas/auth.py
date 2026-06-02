from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """El campo `identifier` acepta email o nombre de usuario;
    el backend decide cuál es según si contiene '@'."""
    identifier: str = Field(..., min_length=1, description="Email o nombre de usuario")
    password: str = Field(..., min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Segundos hasta la expiración")
