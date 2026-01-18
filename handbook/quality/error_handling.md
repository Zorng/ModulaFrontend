# Error Handling & UX

## Production messaging (non-negotiable)
- Default user-facing message: `Oops, something went wrong.`
- Do not show raw `DioException`, stack traces, or network-layer errors in production UI.
- Show a retry action when safe/possible.

## Developer vs production mode
- Developer error visibility is configured through `.env` (e.g., `SHOW_DEBUG_ERRORS=true|false`).
- In dev mode, technical details may be shown (prefer an expandable “Details” section).
- In production, technical details go to logs/crash reporting, not UI.

## Loading UX (non-negotiable)
- Any backend call must surface a loading state in UI (no freezing).

