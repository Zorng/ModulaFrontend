# Runbook (Setup + Common Workflows)

## What this app is
- Flutter app targeting **web first** (mobile later).
- Backend is expected at `API_BASE_URL` (default `http://localhost:3000`).

## Toolchain + demo accounts
- Toolchain pinning: `handbook/handover/toolchain.md`
- Demo logins: `handbook/handover/demo_accounts.md`
- Runtime config guide: `handbook/handover/dart_define_run_guide.md`

## Environment and runtime config

Primary approach: use `--dart-define` for run/build config.

Correct flag:
- `--dart-define` (not `--dart--define`)

The app reads config in this order (`lib/core/config/app_env.dart`):
1. `--dart-define`
2. `.env` fallback (non-web startup path)
3. defaults in `AppEnv`

## Optional `.env` fallback

For local non-web/dev convenience, you can still use `.env` (example: `.env.example`).

Create your local env file:
- `cp .env.example .env`

Common keys:
- `API_BASE_URL` (default `http://localhost:3000`)
- `AUTH_API_PREFIX` (default `/v1/auth`)
- `MENU_API_PREFIX` (default `/v1/menu`)
- `INVENTORY_API_PREFIX` (default `/v1/inventory`)
- `SALES_API_PREFIX` (default `/v1/sales`)
- `CASH_API_PREFIX` (default `/v1/cash`)
- `REPORTING_API_PREFIX` (default `/v1/reports`)
- `POLICY_API_PREFIX` (default `/v1/policies`)
- `ATTENDANCE_API_PREFIX` (default `/v1/attendance`)
- `SHOW_DEBUG_ERRORS` (default false in release; see `lib/core/config/app_env.dart`)

## How to run

### Web (dev)
- `flutter pub get`
- `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`
- easier local option:
  - `cp .env.web.local.example .env.web.local`
  - `bash scripts/run-web-local.sh`

### Mobile (dev)
- `flutter pub get`
- `flutter run -d <device> --dart-define=API_BASE_URL=http://localhost:3000`

## Backend (dev)
Backend runs in a separate repo:
- Repo: `https://github.com/Zorng/ModulaBackend`
- Use branch: `dev`

For DB/migrations/seed/demo accounts, follow the backend repo’s own runbook/wizard (source of truth lives in that repo).

Minimum startup command (per current team convention):
- `pnpm dev`

## Core flows to know

### Login → tenant selection → portal
- Login returns an auth session that may require tenant selection.
- If the user has multiple tenants, they are routed to tenant selection.
- After selecting tenant, user lands on the correct portal for that role/tenant.

### Policy hydration
- Policies are branch/tenant scoped and must be hydrated after session context changes.
- Reference: `lib/core/hydration/app_hydration_listener.dart`
- Architecture note: `handbook/architecture/overview.md` (Hydration section)

### Cash session requirement (product rule)
- Cash sessions are mandatory for sale mutation/finalize.
- Browsing may be allowed, but draft cart creation should be blocked without a session.

## Common failures and where to look

### 401 Unauthorized
- Check token injection: `lib/core/network/dio_client.dart` (Authorization header)
- Ensure backend accepts the token for the current tenant/branch context.

### CORS / “XMLHttpRequest onError” (web)
- If the frontend sends custom headers, backend must allow them in CORS preflight and not block `OPTIONS`.
- Confirm backend allows at least: `Content-Type`, `Authorization` (and any additional headers the frontend adds later).
- If this breaks suddenly after backend changes, check server CORS config first (common root cause).

### 404 Not Found
- Verify API prefixes in your `--dart-define` values (or `.env` fallback) and the endpoint in `docs/apiContracts/**`.
- Ensure the correct query parameters are present (e.g., `branchId`).

### “UI freezes” during API calls
- Backend-dependent UI must show loading/error/data; avoid hidden async work in provider `build()`.
- Reference: `handbook/non_negotiables.md` and `handbook/architecture/providers.md`.
