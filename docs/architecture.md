# Architecture

## System overview

```text
Flutter client
  ├── Presentation: screens, controllers, UI states, accessibility
  ├── Domain: HomeItem and MaintenanceTask value models
  ├── Data: repositories, Dio API client, Hive cache, mock source
  └── Core: routing, theme, localization, secure token storage

FastAPI service
  ├── API routes: validation and HTTP mapping
  ├── Services: authentication and household business rules
  ├── Repositories: database access and pagination
  ├── Models: SQLAlchemy entities
  └── Infrastructure: config, security, logging, rate limiting, migrations

PostgreSQL
  └── Users, households, items and maintenance tasks
```

## Mobile

The Flutter client is feature-first and uses Riverpod for dependency injection and state ownership. Repositories return typed results and preserve a local Hive cache for graceful degradation. `USE_MOCK_DATA=true` uses a deterministic in-process data source and is the default developer experience.

Network failures never expose raw server payloads to a user. A repository maps transport and API errors to concise domain-facing messages, while structured diagnostics remain available only in safe development logs.

Tokens and the minimal session profile needed for a safe app restart are written only through `flutter_secure_storage`; neither is stored in source code, Hive cache, or analytics payload. Inventory and maintenance snapshots are namespaced by authenticated user and active household. A sign-out clears those snapshots and invalidates session-bound Riverpod state before another account can use the device.

## API

FastAPI routes remain thin. They validate input, resolve the current user, and delegate to service/repository logic. SQLAlchemy models are not returned directly to API clients. Pydantic schemas define the public contract.

Authentication uses short-lived access tokens and longer-lived refresh tokens. Passwords are hashed with Argon2 through `pwdlib`, and passwords are never logged. Every authenticated resource checks ownership of the user’s household before returning or changing data.

## Error strategy

- `422`: validation errors from Pydantic with field-level details.
- `401`: absent, expired, invalid, or wrong-type token.
- `403`: authenticated user does not own requested household data.
- `404`: resource does not exist or is intentionally hidden from a non-owner.
- `409`: unique/conflict conditions where relevant.
- `429`: local process rate limit exceeded.
- `500`: generic safe response; exception context is logged without secrets.

## Storage strategy

- PostgreSQL is the server source of truth.
- Hive is a client-side read cache used for previously loaded inventory, maintenance tasks and completion history.
- Every remote cache key includes both the active user and household boundary.
- The local cache is deleted on sign-out; failed cache cleanup cannot prevent the user from leaving the authenticated area.
- The first iteration performs explicit refresh rather than background conflict resolution.
- Sensitive session data uses the platform secure storage abstraction.

## Testing strategy

- API route tests use a SQLite test database and dependency overrides.
- Auth, ownership checks, pagination and validation are covered by pytest.
- Flutter controller tests use repository fakes.
- Flutter cache tests verify household and user isolation; secure storage tests cover session restore, invalid session cleanup and credential/session deletion.
- A widget smoke test verifies that the dashboard has a usable empty/loading-ready render path.
- GitHub Actions runs tests and static analysis on pull requests and pushes.

## Dependency choices

| Dependency | Reason |
| --- | --- |
| Riverpod | Testable DI and explicit async screen states. |
| GoRouter | Declarative, typed-enough navigation structure for Flutter. |
| Dio | Interceptors, cancellation and uniform network errors. |
| Hive | Lightweight local cache without generated code for the MVP. |
| Flutter Secure Storage | Keychain/Keystore-backed token storage. |
| FastAPI | Typed REST API and automatic OpenAPI documentation. |
| SQLAlchemy + Alembic | Mature relational modeling and reproducible migrations. |
| Pydantic Settings | Explicit configuration with environment-based secrets. |
| PyJWT + pwdlib | Standard JWT creation and Argon2 password hashing. |
