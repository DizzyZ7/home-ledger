# Contributing to HomeLedger

Thank you for considering a contribution.

## Before opening an issue

1. Search existing issues and pull requests.
2. Do not include personal data, appliance serial numbers from real homes, access tokens, screenshots containing addresses, or private URLs.
3. For a security issue, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Development setup

```bash
cp .env.example .env
make api-install
make mobile-install
```

Use mock mode for mobile-only work:

```bash
cd apps/mobile
flutter run --dart-define=USE_MOCK_DATA=true
```

Run the full local checks before pushing:

```bash
make api-lint
make api-test
make mobile-analyze
make mobile-test
```

## Branches and commits

- Create focused branches from `main`, for example `feat/receipt-attachment` or `fix/token-refresh`.
- Keep commits small and imperative: `feat(api): add maintenance completion endpoint`.
- Do not mix formatting-only changes with feature changes without a reason.
- Add or update tests for changed behavior.

## Pull request expectations

Every pull request should explain the user impact, implementation choices, validation commands and any follow-up work. Keep API changes documented through Pydantic response/request models and OpenAPI.

## Code style

- Dart: run `flutter analyze`; favor immutable models and explicit async UI states.
- Python: run Ruff; keep routes thin and avoid logging tokens, passwords or request bodies with sensitive fields.
- Documentation: update README or architecture notes when the public behavior changes.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
