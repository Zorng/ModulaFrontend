## Summary
- 

## What changed
- 

## How to test (manual)
- 

## Checklist (required)
- [ ] CI passes (`flutter analyze`, `flutter test`)
- [ ] No DTO imports in UI/viewmodels
- [ ] No new `StateNotifierProvider` / `StateNotifier`
- [ ] No provider-build side effects (avoid `Future.microtask(load...)` inside `build()`)
- [ ] Backend-dependent UI shows loading/error/data (no “freeze”)
- [ ] Page navigation uses `go_router` (`context.go/push`), not `Navigator.push`
- [ ] Production UI errors are user-safe (`Oops, something went wrong.`) with optional retry
- [ ] Responsive verification done per `docs/responsive_breakpoints.md` (for screens touched)

## References
- PR checklist doc: `handbook/handover/pr_checklist.md`

