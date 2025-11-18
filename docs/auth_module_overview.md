# Auth Module Overview

This document summarizes how the auth module is wired, the network setup, env configuration, and data models, so you can recall the current design without scanning code.

## Environment & Config
- Env file: `.env` (example in `.env.example`), loaded via `flutter_dotenv`. It’s in assets (see `pubspec.yaml`).
- Keys:
  - `API_BASE_URL` (host only, e.g., `http://localhost:3000`)
  - `AUTH_API_PREFIX` (versioned path for auth, e.g., `/v1/auth`)
  - `SALES_API_PREFIX` (reserved for other modules)
- `main.dart` loads env in a try/catch (won’t crash if missing).

## Network (Dio)
- Provider: `dioProvider` (`lib/core/network/dio_client.dart`).
- BaseURL comes from `API_BASE_URL`.
- Interceptor attaches:
  - `Authorization: Bearer <accessToken>` from `authAccessTokenProvider`.
  - `X-Tenant-Id: <tenantId>` from `authTenantIdProvider`.
- LogInterceptor added in debug (responseBody=false).

## Auth API
- File: `lib/features/auth/data/auth_api.dart`.
- `AUTH_API_PREFIX` + `/login`.
- Request body: `{ phone, password }` (phone used as username).
- Response parsed into `AuthSession`:
  - `employee` → User fields (id, first_name, last_name, phone, status).
  - `branch_assignments` → `User.branches` (id/branch_id/branch_name/role/active).
  - `tokens` → `access_token`/`refresh_token` (expiresIn used when present).
  - Role inferred from assignment if not in user JSON.

## Auth Models
- `User`: id, name, role, tenantId, phone, status, branches.
- `UserBranch`: id, name (branch_name), role, active, employeeId, branchId.
- `AuthSession`: user + access/refresh tokens + expiresAt (snapshots store user/branches/tenant).

## State & Providers
- `loginControllerProvider` (StateNotifier) manages `LoginState` (session, isLoading, error).
- On login and initial hydrate, updates:
  - `authAccessTokenProvider` (in-memory token for Dio).
  - `authTenantIdProvider` (in-memory tenant for headers).
- Session snapshot store persists non-sensitive session bits (user, branches, expiries) in SharedPreferences (`auth_session_store.dart`) for reload restore; tokens stay in memory.

## Routing & AuthZ
- `GoRouter` in `app.dart` uses `LoginState.session` to redirect:
  - `/login` when unauthenticated.
  - Admin → `/portal/admin`, Cashier → `/portal/cashier`.
  - Unauthorized portal access → `/404` (errorBuilder).
- Components gallery `/components` is public/dev only.

## Portals (mobile-first)
- Shared layout: `PortalShell` (AppBar with user/avatar/settings; content area).
- Admin portal: two sections (Global vs Branch). If multiple branches, shows a branch picker (bottom sheet on mobile) and separate branch cards; single-branch merges branch features into global.
- Cashier portal: fixed cards (POS, Cash Sessions, Orders, X Report), no branch selector.

## Testing
- Dev dependency: `mocktail`.
- Unit tests in `test/auth/`:
  - `auth_api_parsing_test.dart` validates parsing of backend login payload (role from assignments, tokens mapping).
  - `auth_session_snapshot_test.dart` verifies `AuthSession` snapshot round-trip.
- `flutter test` may require allowing Flutter to update cache (permission issue in some sandboxes).

## Notes / Next Steps
- Token refresh endpoint not yet wired; add when backend contract is available.
- Router/auth gate could be further centralized in a non-autoDispose auth/session provider to avoid microtask syncs.
- Card taps in portals are placeholders; wire to real routes when features are ready.
