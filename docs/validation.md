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

## Household invitation smoke flow

In mock mode, open the household switcher, choose **Вступить по коду**, and submit the visible demo code. The app should return to the switcher with **Дом друзей** marked as the active household.

For the self-hosted flow, register two users, then:

1. Sign in as the household owner and create an invitation from **Участники дома**.
2. Copy the code shown in the one-time dialog. The owner can list or revoke invitation metadata later, but cannot reopen the plaintext code.
3. Sign in as the second user, open **Вступить по коду**, and submit the code.
4. Confirm that the new household becomes active, the user has the `member` role, and the code cannot be used again.

Before contributing, verify that output and screenshots contain no real household records, tokens, passwords, private URLs or personally identifiable information.
