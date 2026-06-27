from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


# Import models so Alembic and tests register all metadata.
from app.models.household import Household  # noqa: E402, F401
from app.models.item import HomeItem  # noqa: E402, F401
from app.models.maintenance import MaintenanceTask  # noqa: E402, F401
from app.models.user import User  # noqa: E402, F401
