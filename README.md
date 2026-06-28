# HomeLedger

> **Know what you own. Never miss maintenance.**

HomeLedger is a self-hosted Flutter mobile app and FastAPI service for inventory, warranties, receipt files, and recurring maintenance.

## Features

- Create, edit, archive, restore, search, and filter household items.
- Track warranties and recurring maintenance with completion history.
- Upload, open, and delete PDF, JPEG, PNG, and WebP receipt attachments.
- Store attachment metadata in PostgreSQL and file bytes in a private Docker volume.
- Require authenticated active-household access for every attachment endpoint.
- Run mobile mock mode without Docker, accounts, API keys, or external services.
- Use RU/EN localization, Material 3 light/dark UI, secure tokens, offline cache, tests, and CI.

## Architecture

```text
apps/mobile       Flutter client, mock mode, secure session and offline cache
services/api      FastAPI API, PostgreSQL migrations and private receipt storage
docs              Product and architecture documentation
.github           CI, issues and PR guidance
```

The Flutter client uses a feature-first presentation/domain/data split. Receipt files have no public URL: the app requests them through an authenticated API endpoint. See [docs/architecture.md](docs/architecture.md).

## Quick start

### Mock mobile app

```bash
make mobile-bootstrap
cd apps/mobile
flutter pub get
flutter run --dart-define=USE_MOCK_DATA=true
```

### Self-hosted API

```bash
cp .env.example .env
# Set a long, unique JWT_SECRET_KEY before deployment.
docker compose up --build
```

API docs: `http://localhost:8000/docs`.

### Connect an Android emulator

```bash
cd apps/mobile
flutter run \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Use `localhost` for iOS Simulator. A physical device needs the LAN address of the development machine.

## Attachment storage

Docker creates the `homeledger_attachments` volume for receipt file bytes. Include it in the same backup plan as PostgreSQL. Use `.env.example` as the template and never commit `.env`, tokens, passwords, private endpoints, backups, or genuine household data.

| Variable | Purpose |
| --- | --- |
| `ATTACHMENT_STORAGE_PATH` | Private directory or Docker volume for receipt files |
| `ATTACHMENT_MAX_BYTES` | Maximum attachment size; default: 10 MiB |
| `ATTACHMENT_MAX_FILES_PER_ITEM` | Maximum receipt files per item; default: 20 |
| `ATTACHMENT_ALLOWED_CONTENT_TYPES` | Comma-separated MIME allowlist |

## Quality

```bash
make api-test
make api-lint
make mobile-test
make mobile-analyze
```

## Roadmap

- [x] Authenticated inventory and maintenance API
- [x] Flutter dashboard, mock mode, local cache and secure sessions
- [x] Warranty, archive, restore, household switching and maintenance history
- [x] Receipt attachments with private self-hosted storage
- [ ] Household invitations and per-household roles
- [ ] Widgets and maintenance reminders
- [ ] Optional encrypted backup export/import

## Open source

Read [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [LICENSE](LICENSE). Maintained by [DizZy](https://github.com/DizzyZ7).
