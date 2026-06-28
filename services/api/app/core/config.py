from functools import lru_cache

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=("../../.env", ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "HomeLedger API"
    app_version: str = "0.1.0"
    api_prefix: str = "/api/v1"
    database_url: str = "postgresql+psycopg://homeledger:change-me-local-only@localhost:5432/homeledger"
    jwt_secret_key: str = Field(min_length=32)
    household_invite_secret_key: str | None = Field(default=None, min_length=32)
    household_invite_default_expires_hours: int = Field(default=72, ge=1, le=168)
    jwt_algorithm: str = "HS256"
    jwt_access_token_expires_minutes: int = Field(default=30, ge=5, le=1440)
    jwt_refresh_token_expires_days: int = Field(default=30, ge=1, le=365)
    cors_origins: str = "http://localhost:3000,http://localhost:8080"
    rate_limit_requests: int = Field(default=120, ge=1, le=10000)
    rate_limit_window_seconds: int = Field(default=60, ge=1, le=3600)
    log_level: str = "INFO"

    @field_validator("household_invite_secret_key", mode="before")
    @classmethod
    def normalize_optional_invite_secret(cls, value: object) -> object:
        if value is None:
            return None
        if isinstance(value, str):
            return value.strip() or None
        return value

    @property
    def parsed_cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    @property
    def invite_code_secret(self) -> str:
        return self.household_invite_secret_key or self.jwt_secret_key


@lru_cache
def get_settings() -> Settings:
    return Settings()
