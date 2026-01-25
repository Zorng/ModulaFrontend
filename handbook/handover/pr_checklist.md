# PR Checklist (Frontend)

## Required (non-negotiable)
- CI passes: `flutter analyze` and `flutter test`
- No DTO imports in UI/viewmodels
- No new `StateNotifierProvider` / `StateNotifier`
- No provider-build side effects (avoid `Future.microtask(load...)` inside `build()`)
- Backend-dependent UI has loading/error/data (no “freeze”)
- Navigation uses `go_router` (`context.go/push`) for pages
- Error messages are user-safe in production (`Oops, something went wrong.` + optional retry)
- Responsive: verify screens touched across breakpoints in `docs/responsive_breakpoints.md`

## When relevant
- API contract change: update fixtures in `test/fixtures/**` + mapping tests
- UI changes: attach screenshots (mobile + wide if touched)
- Cross-cutting changes (routing/network/hydration): request review from owners in `handbook/handover/ownership.md`

