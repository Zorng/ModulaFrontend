# Runtime Config with `--dart-define`

This guide is for teammates running the frontend with environment-specific config.

## Why we use this

- Primary runtime config source is `--dart-define`.
- This avoids web asset loading issues (for example missing `.env` asset).
- It is explicit and CI-friendly for integration sprints where prefixes may change often.

## Important flag spelling

- Correct: `--dart-define`
- Incorrect: `--dart--define`

## Resolution order in app

Config values are read in this order (see `lib/core/config/app_env.dart`):
1. `--dart-define`
2. `.env` fallback (non-web startup path)
3. hardcoded default in `AppEnv`

## Common keys

- `API_BASE_URL`
- `AUTH_API_PREFIX`
- `MENU_API_PREFIX`
- `INVENTORY_API_PREFIX`
- `SALES_API_PREFIX`
- `CASH_API_PREFIX`
- `REPORTING_API_PREFIX`
- `POLICY_API_PREFIX`
- `ATTENDANCE_API_PREFIX`
- `BRANCH_API_PREFIX`
- `DISCOUNT_REPOSITORY_MODE` (`mock` or `api`)
- `ATTENDANCE_REPOSITORY_MODE` (`mock` or `api`)
- `SALE_REPOSITORY_MODE` (`mock` or `api`)
- `SHOW_DEBUG_ERRORS` (`true`/`false`)

Defaults are defined in `lib/core/config/app_env.dart`.

## Web run command (integration example)

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=AUTH_API_PREFIX=/v0/auth \
  --dart-define=MENU_API_PREFIX=/v1/menu \
  --dart-define=INVENTORY_API_PREFIX=/v1/inventory \
  --dart-define=SALES_API_PREFIX=/v1/sales \
  --dart-define=CASH_API_PREFIX=/v1/cash \
  --dart-define=REPORTING_API_PREFIX=/v1/reports \
  --dart-define=POLICY_API_PREFIX=/v1/policies \
  --dart-define=ATTENDANCE_API_PREFIX=/v1/attendance \
  --dart-define=BRANCH_API_PREFIX=/v1/branches \
  --dart-define=DISCOUNT_REPOSITORY_MODE=api \
  --dart-define=ATTENDANCE_REPOSITORY_MODE=api \
  --dart-define=SALE_REPOSITORY_MODE=api \
  --dart-define=SHOW_DEBUG_ERRORS=true
```

## Easier local web run

For local web development, you can keep your run config in an untracked file:

```bash
cp .env.web.local.example .env.web.local
```

Then start the app with:

```bash
bash scripts/run-web-local.sh
```

This script reads `.env.web.local` and forwards the values as `--dart-define`.
It also supports extra `flutter run` args, for example:

```bash
bash scripts/run-web-local.sh --web-port 4000
```

## Mobile run command (example)

```bash
flutter run -d <device> \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=AUTH_API_PREFIX=/v0/auth
```

## CI usage

Use the same keys in build/test steps:

```bash
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com
```

If CI requires different prefixes per environment, pass them explicitly per job.

## Troubleshooting

### I changed a prefix but app still uses old one
- Restart `flutter run` with updated `--dart-define` values.
- Hot reload does not replace compile-time define values.

### I still see `.env` behavior
- Check whether your current command includes the expected `--dart-define` keys.
- Confirm key names exactly match `AppEnv` keys.

### I get backend 404
- Verify prefix and endpoint pair (for example `/v0/auth` vs `/v1/auth`).
- Compare with current contract docs under `docs/apiContracts/`.

## Security note

Do not place secrets in `--dart-define` for web builds. Client-side values are visible in shipped artifacts.
