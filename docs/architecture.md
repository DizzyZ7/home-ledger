# Architecture

## System overview

```text
Flutter client
  ├── Presentation: screens, controllers, UI states, accessibility
  ├── Domain: inventory, maintenance and attachment value models
  ├── Data: repositories, Dio API client, Hive cache, mock source
  └── Core: routing, theme, localization, secure token storage

FastAPI service
  ├── API routes: validation and HTTP mapping
  ├── Services: authentication and household business rules
  ├── Storage: private local receipt adapter
  ├── Models: SQLAlchemy entities
  └── Infrastructure: config, security, logging, rate limiting, migrations

PostgreSQL
  └── Users, households, items, attachment metadata and maintenance tasks

Docker volume
  └── Private receipt file bytes
```

## Mobile

The Flutter client is feature-first and uses Riverpod for dependency injection and state ownership. Repositories return typed results and preserve a local Hive cache for graceful degradation. `USE_MOCK_DATA=true` uses deterministic in-process sources and is the default developer experience.

Network failures never expose raw server payloads to a user. A repository maps transport and API errors to concise domain-facing messages, while structured diagnostics remain available only in safe development logs.

Tokens and the minimal session profile needed for a safe app restart are written only through `flutter_secure_storage`; neither is stored in source code, Hive cache, or analytics payload. Inventory and maintenance snapshots are namespaced by authenticated user and active household. A sign-out clears those snapshots and invalidates session-bound Riverpod state before another account can use the device.

Attachment bytes are intentionally not cached by the app. The user selects a permitted file, the client uploads multipart data, and an explicit authenticated download writes a temporary copy only when the user chooses to open it.

## API

FastAPI routes remain thin. They validate input, resolve the current user, and delegate to storage or database logic. SQLAlchemy models are not returned directly to API clients. Pydantic schemas define the public contract.

Authentication uses short-lived access tokens and longer-lived refresh tokens. Passwords are hashed with Argon2 through `pwdlib`, and passwords are never logged. Every authenticated resource checks ownership of the active household before returning or changing data.

Receipt metadata is stored in PostgreSQL. The local storage adapter writes file bytes under generated opaque keys rather than user-provided paths. It enforces a configurable size limit, a MIME allowlist and a per-item attachment count. Files are downloaded only through authenticated item attachment endpoints; no public storage URL is created.

## Error strategy

- `422`: validation errors from Pydantic with field-level details.
- `401`: absent, expired, invalid, or wrong-type token.
- `403`: authenticated user does not own requested household data.
- `404`: resource does not exist or is intentionally hidden from a non-owner.
- `409`: unique/conflict conditions, including attachment count limits.
- `413`: attachment exceeds the configured byte limit.
- `415`: unsupported attachment content type.
- `429`: local process rate limit exceeded.
- `500`: generic safe response; exception context is logged without secrets.

## Storage strategy

- PostgreSQL is the server source of truth for metadata.
- A Docker-managed volume stores private attachment bytes outside PostgreSQL.
- Hive is a client-side read cache used for previously loaded inventory, maintenance tasks and completion history.
- Every remote cache key includes both the active user and household boundary.
- The local cache is deleted on sign-out; failed cache cleanup cannot prevent the user from leaving the authenticated area.
- The first iteration performs explicit refresh rather than background conflict resolution.
- Sensitive session data uses the platform secure storage abstraction.

## Testing strategy

- API route tests use a SQLite test database, a temporary attachment directory and dependency overrides.
- Auth, ownership checks, pagination, validation, attachment download and file cleanup are covered by pytest.
- Flutter controller tests use repository fakes.
- Flutter attachment repository tests cover mock upload, download and deletion.
- Flutter cache tests verify household and user isolation; secure storage tests cover session restore, invalid session cleanup, token rotation and credential/session deletion.
- Widget smoke tests verify the item detail receipt section together with the existing dashboard state.
- GitHub Actions runs tests and static analysis on pull requests and pushes.

## Dependency choices

| Dependency | Reason |
| --- | --- |
| Riverpod | Testable DI and explicit async screen states. |
| GoRouter | Declarative, typed-enough navigation structure for Flutter. |
| Dio | Multipart uploads, downloads, interceptors and uniform network errors. |
| Hive | Lightweight local cache without generated code for the MVP. |
| Flutter Secure Storage | Keychain/Keystore-backed token storage. |
| File Picker + Open Filex | Native receipt selection and explicit opening through the platform viewer. |
| FastAPI | Typed REST API and automatic OpenAPI documentation. |
| SQLAlchemy + Alembic | Mature relational modeling and reproducible migrations. |
| Pydantic Settings | Explicit configuration with environment-based secrets. |
| PyJWT + pwdlib | Standard JWT creation and Argon2 password hashing. |
