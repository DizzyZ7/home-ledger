from fastapi import APIRouter

from app.api.dependencies import DbSession
from app.core.errors import DomainError
from app.core.security import TokenError, decode_token
from app.models.user import User
from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, RegisterRequest, TokenPair
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse, status_code=201)
def register(payload: RegisterRequest, session: DbSession) -> AuthResponse:
    return AuthService.register(session, payload)


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, session: DbSession) -> AuthResponse:
    return AuthService.login(session, payload)


@router.post("/refresh", response_model=TokenPair)
def refresh(payload: RefreshRequest, session: DbSession) -> TokenPair:
    try:
        user_id = decode_token(payload.refresh_token, expected_type="refresh")
    except TokenError as exc:
        raise DomainError(401, "invalid_refresh_token", "Refresh token is invalid or expired.") from exc

    if session.get(User, user_id) is None:
        raise DomainError(401, "invalid_refresh_token", "Refresh token is invalid or expired.")
    return AuthService.token_pair(user_id)
