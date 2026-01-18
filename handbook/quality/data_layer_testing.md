# Testing Data Layer (Auth-focused)

This guide covers how to run and extend unit tests for the data layer. UI is currently tested manually.

## Prereqs
- Dev dependencies: `flutter_test`, `mocktail` (see `pubspec.yaml`).
- `.env` should exist for runtime, but tests are isolated and use fixtures/mocks.

## Running tests
- All tests: `flutter test`
- Specific file: `flutter test test/auth/auth_api_parsing_test.dart`

## Current auth tests
- `test/auth/auth_api_parsing_test.dart`:
  - Verifies login payload parsing: role from `branch_assignments`, tokens mapping (access/refresh), basic user fields.
- `test/auth/auth_session_snapshot_test.dart`:
  - Ensures `AuthSession.toJson/fromJson` round-trip user/tenant/branch data.

## What to add next
- **Auth API error handling**: mock/fake backend payloads for 401/422; assert repository surfaces user-friendly errors.
- **Dio interceptor headers**: set `authAccessTokenProvider` and `authTenantIdProvider` in a `ProviderContainer`; inspect request headers via a mock adapter to ensure `Authorization`/`X-Tenant-Id` are set.
- **LoginController state**: fake `AuthRepository` to return a session or throw; assert state transitions (`isLoading`, `session`, `error`) and that token/tenant providers are updated.
- **Auth role/routing logic** (optional): unit-test the `GoRouter` redirect function with different `LoginState.session` shapes (admin/cashier/unauthenticated) to confirm expected paths (`/portal/admin`, `/portal/cashier`, `/404`, `/login`).

## Patterns to follow
- Use pure Dart fixtures where possible (no widget binding).
- For parsing: create maps matching backend responses and feed them into model constructors.
- For providers: use `ProviderContainer` to override/mock dependencies (e.g., `authRepositoryProvider`) and observe state.
- Keep tests deterministic: avoid real network/disk; rely on fakes/mocks and fixture data.

UI remains manually tested for now; add widget/integration tests when flows stabilize.
