# ADR 0001: Mock-first mobile development

- **Status:** Accepted
- **Date:** 2026-06-27

## Context

HomeLedger must be usable by contributors, reviewers and portfolio visitors without a cloud account, paid API key, Docker installation or external data. At the same time, the production architecture needs a real backend path that exercises network failures, secure sessions and local caching.

## Decision

The Flutter client exposes an explicit build-time `USE_MOCK_DATA` flag. It defaults to `true` and swaps repository implementations through Riverpod:

- `MockHomeItemRepository` supplies deterministic synthetic inventory data in memory.
- `RemoteHomeItemRepository` uses the self-hosted FastAPI service and maintains a Hive read cache.
- Secure session storage and API configuration remain separate from the item repository, so mock mode cannot leak a real token into source control.

The dashboard visibly communicates that demo mode is active once the corresponding UI notice is enabled in the mobile feature branch.

## Consequences

### Positive

- A new contributor can run the main mobile scenario immediately.
- Reviewers can inspect UX and state handling without infrastructure setup.
- Tests can replace repositories with small fakes instead of relying on live HTTP.
- No paid or third-party service is needed for the baseline demo.

### Trade-offs

- Mock and remote behavior need contract-focused tests as features grow.
- Some production synchronization behavior cannot be reproduced fully in mock mode.
- Features that require server authority, such as household membership, must retain an API integration test path.

## Revisit when

Revisit this decision when offline writes and conflict resolution are introduced. At that point, mock mode should model pending operations and sync outcomes rather than only preloaded data.
