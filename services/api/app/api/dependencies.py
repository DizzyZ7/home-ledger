from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.errors import DomainError
from app.core.security import TokenError, decode_token
from app.db.session import get_db
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], session: DbSession) -> User:
    try:
        user_id = decode_token(token, expected_type="access")
    except TokenError as exc:
        raise DomainError(401, "invalid_token", "Your session is invalid or expired.") from exc

    user = session.get(User, user_id)
    if user is None:
        raise DomainError(401, "invalid_token", "Your session is invalid or expired.")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
