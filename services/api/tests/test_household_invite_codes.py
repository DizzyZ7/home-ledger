from datetime import UTC, datetime, timedelta

from app.api.routes.households import _invite_is_expired
from app.services.household_invites import create_household_invite_code, household_invite_code_hash


def test_generated_code_can_be_hashed_after_normalization():
    code = create_household_invite_code()

    assert code.startswith("HL-")
    assert household_invite_code_hash(code) == household_invite_code_hash(code.lower().replace("-", " "))


def test_expiry_accepts_naive_and_aware_datetimes():
    now = datetime(2026, 6, 28, 12, tzinfo=UTC)

    assert _invite_is_expired(datetime(2026, 6, 28, 11), now)
    assert not _invite_is_expired(now + timedelta(seconds=1), now)
