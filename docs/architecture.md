# Architecture

## System overview

```text
Flutter client
  ├── Presentation: screens, controllers, UI states, accessibility
  ├── Domain: inventory, maintenance, household and invitation value models
  ├── Data: repositories, Dio API client, Hive cache, mock source
  └── Core: routing, theme, localization, secure token storage

FastAPI service
  ├── API routes: validation and HTTP mapping
  ├── Services: authentication, household access and invite-code derivation
  ├── Models: SQLAlchemy entities
  └── Infrastructure: config, security, logging, rate limiting, migrations

PostgreSQL
  └── Users, households, membership, invitation metadata, items and maintenance tasks
```

## Mobile

The Flutter client is feature-first and uses Riverpod for dependency injection and state ownership. Repositories return typed results and preserve a local Hive cache for graceful degradation. `USE_MOCK_DATA=true` uses a deterministic in-process data source and is the default developer experience.

Network failures never expose raw server payloads to a user. A repository maps transport and API errors to concise domain-facing messages, while structured diagnostics remain available only in safe development logs.

Tokens are written only through `flutter_secure_storage`; no token is stored in source code, Hive cache, or analytics payload. Invitation codes are not retained in app cache: the owner sees the plaintext value once after generation and can copy it deliberately.

## API

FastAPI routes remain thin. They validate input, resolve the current user, and delegate to service/repository logic. SQLAlchemy models are not returned directly to API clients. Pydantic schemas define the public contract.

Authentication uses short-lived access tokens and longer-lived refresh tokens. Passwords are hashed with Argon2 through `pwdlib`, and passwords are never logged. Every authenticated resource checks ownership of the user’s household before returning or changing data.

A household owner can create and revoke one-time invitation codes. The database stores only an HMAC-SHA256 digest with expiration, acceptance and revocation metadata; it never stores the plaintext code. The digest uses a dedicated optional secret or a domain-separated fallback derived from the configured JWT secret. A code is accepted only by an authenticated user who is not already a member, then becomes invalid atomically and activates the joined household for that user.

## Error strategy

- `422`: validation errors from Pydantic with field-level details.
- `401`: absent, expired, invalid, or wrong-type token.
- `403`: authenticated user does not own requested household data.
- `404`: resource does not exist or is intentionally hidden from a non-owner; invalid, expired, revoked and consumed invite codes share the same safe response.
- `409`: unique/conflict conditions, including already-member and inactive-invite attempts.
- `429`: local process rate limit exceeded.
- `500`: generic safe response; exception context is logged without secrets.

## Storage strategy

- PostgreSQL is the server source of truth.
- Hive is a client-side read cache used for a previously loaded item list.
- Invitation plaintext is excluded from both PostgreSQL and Hive.
- The first iteration performs explicit refresh rather than background conflict resolution.
- Sensitive session data uses the platform secure storage abstraction.

## Testing strategy

- API route tests use a SQLite test database and dependency overrides.
- Auth, ownership checks, pagination, validation, invitation lifecycle and code normalization are covered by pytest.
- Flutter controller and repository tests use in-process mocks plus Dio interceptor contract checks.
- Widget smoke tests verify owner-only invitation controls and the item/dashboard render path.
- GitHub Actions runs tests and static analysis on pull requests and pushes.

## Dependency choices

| Dependency | Reason |
| --- | --- |
| Riverpod | Testable DI and explicit async screen states. |
| GoRouter | Declarative navigation structure for Flutter. |
| Dio | Interceptors and uniform network errors. |
| Hive | Lightweight local cache without generated code for the MVP. |
| Flutter Secure Storage | Keychain/Keystore-backed token storage. |
| FastAPI | Typed REST API and automatic OpenAPI documentation. |
| SQLAlchemy + Alembic | Mature relational modeling and reproducible migrations. |
| Pydantic Settings | Explicit configuration with environment-based secrets. |
| PyJWT + pwdlib | Standard JWT creation and Argon2 password hashing. |
