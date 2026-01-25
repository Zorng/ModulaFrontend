# Known Issues

Purpose: stop re-debugging the same problems.

Format:
- **Symptom**
- **Impact**
- **Workaround**
- **Owner**
- **Jira**

## Template

### Issue: <short title>
- Symptom:
- Impact:
- Workaround:
- Owner:
- Jira:

## Issues (seeded)

### Issue: Web requests fail with `XMLHttpRequest onError` (CORS preflight)
- Symptom: Dio reports a connection error on web; Network tab shows no response on API calls.
- Impact: Screens that rely on backend data fail to load.
- Workaround:
  - If the frontend sends custom headers (common examples: `Authorization`, tenant/branch headers), backend CORS must allow them in `allowedHeaders` and must not block `OPTIONS` preflight.
  - Restart backend after CORS changes.
- Owner: Backend
- Jira: TBD

### Issue: “UI freezes” during backend calls (no loading state)
- Symptom: UI becomes unresponsive during an action until the backend call completes.
- Impact: Poor UX and accidental double-taps; hides failure modes.
- Workaround:
  - Treat backend truth as async and render loading/error/data (`AsyncValue`).
  - Avoid triggering network work inside provider `build()`; use explicit `load()/refresh()`.
- Owner: Frontend
- Jira: TD-001 (historical); file a new bug if it regresses

### Issue: E2E testing not wired yet (web + mobile)
- Symptom: No browser automation suite exists in-repo.
- Impact: Regressions still require manual end-to-end checks.
- Workaround:
  - Use unit/widget tests + CI gates for now (`handbook/quality/testing.md`).
  - Plan: Playwright for web E2E and `integration_test` for mobile (deferred until stable test server + keys).
- Owner: Frontend
- Jira: Epic 3 Story 3.6 (deferred)
