# Release / Demo Checklist

This is a lightweight checklist to make demos/releases repeatable.

## Before you start
- Backend is running and reachable from `API_BASE_URL`
- Clear stale state if needed (log out; hard refresh for web)

## Smoke flows (web)
- Login (single tenant) → portal loads
- Login (multi tenant) → tenant selection → portal loads
- Branch switch (if available) does not crash; policy refreshes
- Cash session:
  - Open cash session
  - Close cash session
- Sale:
  - Browse menu
  - With open cash session: add item → create cart → checkout
  - Without cash session: verify cart creation is blocked (per product rules)
- Reporting:
  - X report shows sessions for selected date/status
  - Z report: generate + refresh (throttle enforced)

## Quick regression checks
- Inventory loads (stock items list)
- Inventory journal loads for a branch

