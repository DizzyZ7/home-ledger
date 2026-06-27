from pydantic import EmailStr, Field

from app.schemas.common import APIModel


class RegisterRequest(APIModel):
    email: EmailStr
    display_name: str = Field(min_length=2, max_length=80)
    password: str = Field(min_length=12, max_length=128)


class LoginRequest(APIModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class RefreshRequest(APIModel):
    refresh_token: str = Field(min_length=1)


class UserResponse(APIModel):
    id: str
    email: EmailStr
    display_name: str


class TokenPair(APIModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AuthResponse(TokenPair):
    user: UserResponse
