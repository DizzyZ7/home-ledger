# HomeLedger

> **Know what you own. Never miss maintenance.**

HomeLedger is a self-hosted mobile application and REST API for cataloging household items, tracking warranties and receipts, and planning recurring maintenance. It is designed for people who want practical control over appliances and home equipment without sending their inventory to a proprietary cloud by default.

The repository is intentionally production-oriented: Flutter client, FastAPI backend, PostgreSQL, JWT sessions, migrations, tests, Docker Compose, CI, RU/EN localization, a safe mock mode, and no paid API dependency for the baseline demo.

## Why it exists

Household information usually fragments across paper receipts, chat messages, photo galleries, and memory. When an appliance fails, it becomes hard to find the model, warranty date, purchase record, or the last time it was serviced. HomeLedger keeps that information in a small, understandable system that can run locally.

## MVP

- Add, view, edit, archive, and restore household items through the REST API and Flutter UI.
- Keep warranty expiry, purchase date, serial number, location, and notes.
- Track recurring maintenance tasks, complete them, and inspect completion history.
- See actionable expiring-warranty and overdue-maintenance indicators in the mobile dashboard.
- Switch between households without mixing active UI state or offline snapshots.
- Work in a mock-first mobile mode without starting backend services.
- Use a self-hosted FastAPI + PostgreSQL backend with registration and sign-in.
- Use Russian and English UI strings with system light/dark theme support.

## Screenshots

> Add real, redacted screenshots under `docs/images/` and replace these placeholders before the first public release.

| Dashboard | Item editor | Maintenance |
| --- | --- | --- |
| `docs/images/dashboard.png` | `docs/images/item-editor.png` | `docs/images/maintenance.png` |

## Tech stack

| Area | Choice |
| --- | --- |
| Mobile | Flutter, Dart, Riverpod, GoRouter, Dio, Hive, Flutter Secure Storage |
| Backend | FastAPI, SQLAlchemy 2, Alembic, Pydantic Settings, JWT, Argon2 password hashing |
| Database | PostgreSQL 16 |
| Quality | pytest, Flutter tests, Ruff, GitHub Actions |
| Local development | Docker Compose, Make |

## Architecture

The repository is a monorepo with clear product boundaries:

```text
apps/mobile       Flutter client, mock mode, secure session, local cache, presentation and domain layers
services/api      FastAPI service, migrations, tests and seed data
docs              Product, architectural and release documentation
.github           CI, issue templates and pull request guidance
```

The mobile app follows feature-first Clean Architecture with a presentation/domain/data split. The API is layered into routes, services, models and infrastructure. Offline inventory and maintenance snapshots are scoped to both the signed-in user and active household, then purged on sign-out. See [docs/architecture.md](docs/architecture.md).

## Quick start

### 1. Start with mock data only

```bash
make mobile-bootstrap
cd apps/mobile
flutter pub get
flutter run --dart-define=USE_MOCK_DATA=true
```

`mobile-bootstrap` generates the standard Android and iOS platform shells from the Flutter SDK. The source code, dependencies, app configuration and tests are already versioned; committing the generated shells is recommended before publishing a store build. Mock mode is the default, so the mobile app stays usable without Docker, accounts, or API keys.

### 2. Start the self-hosted backend

```bash
cp .env.example .env
# Replace JWT_SECRET_KEY in .env before exposing the API outside your machine.
docker compose up --build
```

Open API docs at `http://localhost:8000/docs` and health status at `http://localhost:8000/health`.

Optional safe demo data:

```bash
docker compose exec api python -m app.scripts.seed
```

This creates only synthetic local data: `demo@homeledger.local` and a deliberately non-production password printed in the command output.

### 3. Connect Flutter to local API

For an Android emulator:

```bash
cd apps/mobile
flutter run \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

For iOS Simulator, replace `10.0.2.2` with `localhost`. A physical device must use the LAN address of the machine running the API and an appropriate development network configuration.

## Tests and quality checks

```bash
make api-test
make api-lint
make mobile-test
make mobile-analyze
```

## Environment variables

Use `.env.example` as the only template. Do not commit `.env`, access tokens, passwords, private endpoints, backups, or genuine household data.

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | SQLAlchemy connection string used by the API |
| `JWT_SECRET_KEY` | Secret used to sign access and refresh tokens |
| `CORS_ORIGINS` | Comma-separated web origins allowed by API CORS |
| `RATE_LIMIT_REQUESTS` | Requests allowed per window for a client IP |
| `RATE_LIMIT_WINDOW_SECONDS` | Rate limiting window duration |

## Roadmap

- [x] Public architecture and self-hosted development environment
- [x] Authenticated item and maintenance REST API
- [x] Flutter dashboard, mock mode, local cache and sign-in foundation
- [x] Item details, editing, archiving and restoration UX
- [x] Warranty overview, filtering and attention indicators
- [x] Maintenance creation, editing, recurring completion and history
- [x] Household switching, members and household-scoped offline data
- [x] Session-scoped secure offline cache boundaries and logout cleanup
- [ ] Receipt photo attachments through a pluggable local storage adapter
- [ ] Household invitations and per-household roles
- [ ] Widgets and maintenance reminders
- [ ] Optional encrypted backup export/import

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), follow the [Code of Conduct](CODE_OF_CONDUCT.md), and use the included issue and pull request templates.

## License

HomeLedger is released under the [MIT License](LICENSE).

## Security

Report vulnerabilities privately using the process in [SECURITY.md](SECURITY.md). Do not publish secrets or a proof of concept that exposes real user data.

## Author

Maintained by [DizZy](https://github.com/DizzyZ7). For public project discussions, use GitHub Issues and Discussions rather than posting personal data.
