# Navigation & Routing

## Source of truth
- Routes are defined centrally in `lib/app.dart` (`appRouterProvider`) and enumerated in `lib/core/routing/app_router.dart` (`AppRoute`).

## Page navigation (non-negotiable)
- Use `go_router` (`context.go(...)` / `context.push(...)`) for **pages**.
- Do not use `Navigator.of(context).push(...)` for pages.
- `Navigator.pop(...)` is allowed for dialogs/modals and returning selection results.

## Stack guidance
- Use `context.go(...)` for switching destinations (portal/home/tab) to avoid confusing back behavior.
- Use `context.push(...)` for details/sub-pages.

## Route parameters
- Prefer passing **IDs** (path/query) over passing full objects via `extra` (exceptions only for short-lived flows).

## Responsive navigation
See `docs/responsive_breakpoints.md` for breakpoint behavior requirements.

