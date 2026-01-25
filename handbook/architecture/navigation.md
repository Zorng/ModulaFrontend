# Navigation & Routing

This document defines the **canonical navigation model** for the app. It replaces older rules and is the source of truth.

## Source of truth
- Routes are defined centrally in `lib/app.dart` (`appRouterProvider`) and enumerated in `lib/core/routing/app_router.dart` (`AppRoute`).
- Route builders live under `lib/core/routing/routes/`.

## Non‑negotiables (page navigation)
- Use `go_router` for **pages**:
  - `context.go(...)` for switching destinations.
  - `context.push(...)` for details/sub-pages.
- Do **not** use `Navigator.of(context).push(...)` for pages.
- `Navigator.pop(...)` is allowed for dialogs/modals and returning selection results.

## Canonical paths (no role‑scoped URLs)
- **All feature roots are role‑agnostic** (example: `/sale`, `/menu`, `/inventory`, `/cash/session`).
- Do not create role‑scoped routes like `/portal/admin/...` or `/portal/cashier/...`.
- Authorization happens in the router redirect + page gating, **not** by duplicating routes per role.

### Examples
- Good: `/sale`, `/reports/x`, `/attendance/manage`
- Avoid: `/portal/admin/sale`, `/cashier/cash-session`

## Mobile navigation model (feature portal + tabs)
Mobile uses a **two‑layer** model:

1) **Portal** (feature hub)
   - `AppRoute.portal` is the entry for choosing features.
   - Portal pages exist **only for mobile**.

2) **Feature root + internal tabs**
   - Feature root pages (e.g. `/sale`, `/menu`, `/inventory`) use a bottom‑nav shell *only inside that feature*.
   - Bottom nav is for **feature tabs** (not global app navigation).
   - Use `IndexedStack` to preserve tab state.
   - On mobile web, bottom nav can auto‑hide while scrolling (UX rule).

### Mobile app bar rule
- Feature root pages show a **Home** icon that returns to the portal.
- Detail pages use the standard back affordance.

## Wide screen navigation model (rail + content)
Wide screens use a **single shell**:

- Left **NavigationRail** is always visible.
- Content switches inside the rail shell (no scaffold replacement).
- **No back button** on wide‑screen feature roots (rail is primary navigation).
- Profile header is **display only**; Account/Settings are rail destinations.
- Branch selector lives **under the Branch section** in the rail.

## Destination switching rules
- Use `context.go(...)` when switching **features** or **rail destinations**.
- Use `context.push(...)` for **detail pages** within a feature.

## Detail pages & modals
- Detail pages are normal routes and should be reachable via deep links.
- Use modals/bottom sheets only for short flows or transient input.

## Router authorization
Authorization checks live in the router redirect (role + policy + session).
Do not create duplicate routes per role; use a single route and **gate the content**.

## Implementation notes
- Navigation shells should be centralized:
  - `AppWideNavigationRailShell` for wide screens.
  - `AppBottomNavShellScaffold` for feature tabs on mobile.
- Pages should not implement their own global navigation controls.

