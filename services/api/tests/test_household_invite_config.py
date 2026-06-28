from app.core.config import Settings


def test_blank_optional_invite_secret_falls_back_to_jwt_secret():
    settings = Settings(
        jwt_secret_key="a" * 32,
        household_invite_secret_key="   ",
    )

    assert settings.household_invite_secret_key is None
    assert settings.invite_code_secret == "a" * 32


def test_dedicated_invite_secret_is_used_when_configured():
    settings = Settings(
        jwt_secret_key="a" * 32,
        household_invite_secret_key="b" * 32,
    )

    assert settings.invite_code_secret == "b" * 32
