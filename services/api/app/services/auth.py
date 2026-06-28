from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import DomainError
from app.core.security import create_access_token, create_refresh_token, hash_password, verify_password
from app.models.household import Household, HouseholdMember
from app.models.user import User
from app.schemas.auth import AuthResponse, LoginRequest, RegisterRequest, TokenPair, UserResponse


class AuthService:
    @staticmethod
    def register(session: Session, payload: RegisterRequest) -> AuthResponse:
        email = str(payload.email).lower()
        existing = session.scalar(select(User).where(User.email == email))
        if existing:
            raise DomainError(409, "email_taken", "An account with this email already exists.")

        user = User(
            email=email,
            display_name=payload.display_name.strip(),
            password_hash=hash_password(payload.password),
        )
        household = Household(name=f"{user.display_name}'s home", owner=user)
        session.add_all([user, household])
        try:
            session.flush()
            user.active_household_id = household.id
            session.add(
                HouseholdMember(
                    household_id=household.id,
                    user_id=user.id,
                    role="owner",
                )
            )
            session.commit()
        except IntegrityError as exc:
            session.rollback()
            raise DomainError(409, "email_taken", "An account with this email already exists.") from exc
        session.refresh(user)
        return AuthService._auth_response(user)

    @staticmethod
    def login(session: Session, payload: LoginRequest) -> AuthResponse:
        user = session.scalar(select(User).where(User.email == str(payload.email).lower()))
        if user is None or not verify_password(payload.password, user.password_hash):
            raise DomainError(401, "invalid_credentials", "Email or password is incorrect.")
        return AuthService._auth_response(user)

    @staticmethod
    def token_pair(user_id: str) -> TokenPair:
        return TokenPair(
            access_token=create_access_token(user_id),
            refresh_token=create_refresh_token(user_id),
        )

    @staticmethod
    def _auth_response(user: User) -> AuthResponse:
        tokens = AuthService.token_pair(user.id)
        return AuthResponse(
            access_token=tokens.access_token,
            refresh_token=tokens.refresh_token,
            user=UserResponse.model_validate(user),
        )
