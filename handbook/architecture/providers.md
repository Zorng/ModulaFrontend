# Providers & State Management (Riverpod)

This document defines provider conventions to keep state predictable and prevent circular dependencies.

## Provider type defaults
- Local/UI truth: `NotifierProvider` + `Notifier`
- Backend truth: `AsyncNotifierProvider` + `AsyncNotifier` (expose `AsyncValue<T>`)
- Dependencies (API/repository): `Provider`
- Do not introduce new legacy `StateNotifierProvider`/`StateNotifier`.
- `StateProvider` is allowed only for trivial toggles; otherwise prefer a screen controller.

## Backend loading style
- Prefer explicit `load()` / `refresh()` methods triggered from UI/controller.
- UI must render loading/error/data states (no freezing).

## `watch` vs `read`
- UI: `watch` for rendering, `read` for event handlers.
- Notifiers: `watch` for stable dependencies; `read` inside actions to reduce circular dependency risk.

