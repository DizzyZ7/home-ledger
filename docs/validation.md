# Validation guide

Run the same checks locally that CI runs on every pushed branch.

```bash
make api-lint
make api-test
make mobile-analyze
make mobile-test
```

For a full self-hosted smoke check:

```bash
cp .env.example .env
docker compose up --build
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

The mobile mock flow does not require Docker or any API key:

```bash
make mobile-bootstrap
cd apps/mobile
flutter pub get
flutter run --dart-define=USE_MOCK_DATA=true
```

Before contributing, verify that output and screenshots contain no real household records, tokens, passwords, private URLs or personally identifiable information.
