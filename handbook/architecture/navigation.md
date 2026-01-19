# Navigation & Routing

## Source of truth
- Routes are defined centrally in `lib/app.dart` (`appRouterProvider`) and enumerated in `lib/core/routing/app_router.dart` (`AppRoute`).

## Page navigation (non-negotiable)
- Use `go_router` (`context.go(...)` / `context.push(...)`) for **pages**.
- Do not use `Navigator.of(context).push(...)` for pages.
- `Navigator.pop(...)` is allowed for dialogs/modals and returning selection results.

## Route authoring guidelines
- New pages must be reachable via a route (deep-linkable).
- Prefer route params/query over global “selection” singletons.
- Prefer IDs:
  - Good: `/menu/items/:id`
  - Avoid: passing a full `MenuItem` in `extra` for long-lived navigation
- `extra` is allowed only for short-lived flows where the data is already in memory and re-fetching would be wasteful (e.g., a form step in the same flow).

## Path conventions (non-negotiable)
- Role-scoped pages live under: `/portal/<role>/...` (example: `/portal/admin/inventory`).
- Cross-role pages live under: `/portal/...` (example: `/portal/x-report`).
- Do not introduce mixed prefixes like `/admin/portal/...` or `/portal/admin/...` for the same module.
- Keep “module root” paths stable and nest sub-pages beneath them (example: `/portal/admin/menu/...`).

## Stack guidance
- Use `context.go(...)` for switching destinations (portal/home/tab) to avoid confusing back behavior.
- Use `context.push(...)` for details/sub-pages.

## Route parameters
- Prefer passing **IDs** (path/query) over passing full objects via `extra` (exceptions only for short-lived flows).

## Responsive navigation
See `docs/responsive_breakpoints.md` for breakpoint behavior requirements.

At a high level:
- **Mobile**: bottom navigation to replace current kebab-driven primary navigation.
  - On mobile web, the bottom nav may auto-hide while scrolling (UX decision).
- **Wide screens**: left navigation rail is always visible; no auto-hide.

Implementation notes:
- Keep the navigation “shell” in one place (e.g., `PortalShell` / router shell route).
- Pages should not implement their own “global” navigation UI.
