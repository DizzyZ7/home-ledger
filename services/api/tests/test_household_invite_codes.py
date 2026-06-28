from datetime import UTC, datetime, timedelta

from app.api.routes.households import _invite_is_expired
from app.services.household_invites import (
    create_household_invite_code,
    household_invite_code_hash,
    normalize_household_invite_code,
)


def test_generated_household_invite_code_normalizes_and_hashes():
    code = create_household_invite_code()

    normalized = normalize_household_invite_code(code)
    assert normalized is not None
    assert normalized.startswith("HL")
    assert len(normalized) == 22

    assert household_invite_code_hash(code) == household_invite_code_hash(code.lower().replace("-", " "))


def test_household_invite_code_rejects_invalid_alphabet_and_shape():
    assert normalize_household_invite_code("HL-ABCD") is None
    assert normalize_household_invite_code("HL-0000-0000-0000-0000-0000") is None
    assert household_invite_code_hash("not-an-invite") is None


def test_invite_expiry_handles_sqlite_naive_and_postgres_aware_datetimes():
    now = datetime(2026, 6, 28, 12, tzinfo=UTC)

    assert _invite_is_expired(datetime(2026, 6, 28, 11), now)
    assert _invite_is_expired(now - timedelta(seconds=1), now)
    assert not _invite_is_expired(datetime(2026, 6, 28, 13), now)
    assert not _invite_is_expired(now + timedelta(seconds=1), now)
