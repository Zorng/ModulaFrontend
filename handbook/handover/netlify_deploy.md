# Netlify Deploy

This project can be deployed to Netlify as a static Flutter web build.

## Branch wiring
- Production branch: `main`
- Netlify imports the GitHub repo and runs the build defined in `netlify.toml`

## Files in repo
- `netlify.toml`
- `scripts/netlify-build.sh`

`netlify.toml` tells Netlify:
- build command: `bash scripts/netlify-build.sh`
- publish directory: `build/web`
- SPA fallback redirect: `/* -> /index.html`

`scripts/netlify-build.sh`:
- installs a released Linux Flutter SDK for Netlify builds
- uses `FLUTTER_CHANNEL` + `FLUTTER_VERSION`
- enables Flutter web
- runs `flutter pub get`
- builds the app with `--dart-define` values coming from Netlify environment variables

Current Netlify pin:

```text
FLUTTER_CHANNEL=stable
FLUTTER_VERSION=3.41.5
```

## Required Netlify environment variables

Set these in:
- `Site configuration -> Environment variables`

Minimum:

```text
API_BASE_URL=https://your-backend.example.com
AUTH_API_PREFIX=/v0/auth
MENU_API_PREFIX=/v0/menu
INVENTORY_API_PREFIX=/v0/inventory
SALES_API_PREFIX=/v0/sales
CASH_API_PREFIX=/v0/cash
REPORTING_API_PREFIX=/v0/reports
POLICY_API_PREFIX=/v0/policy
ATTENDANCE_API_PREFIX=/v0/attendance
BRANCH_API_PREFIX=/v0/branches
```

Recommended repository mode flags:

```text
AUTH_REPOSITORY_MODE=api
TENANT_REPOSITORY_MODE=api
BRANCH_REPOSITORY_MODE=api
INVENTORY_REPOSITORY_MODE=api
POLICY_REPOSITORY_MODE=api
CASH_SESSION_REPOSITORY_MODE=api
ATTENDANCE_REPOSITORY_MODE=api
SHOW_DEBUG_ERRORS=false
```

## Backend requirements

The deployed backend must:
- use HTTPS
- allow CORS from the Netlify site domain
- allow at least:
  - `Authorization`
  - `Content-Type`
  - `OPTIONS`

If you use a custom domain, add that origin too.

## Notes
- Web builds do not load `.env`; this app uses `--dart-define` at build time.
- If Netlify env vars change, trigger a new deploy. Flutter web config is compile-time.
