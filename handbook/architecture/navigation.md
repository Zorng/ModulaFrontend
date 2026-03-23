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

## Tenant workspace navigation model
Tenant workspace keeps the older responsive shell split:

### Non-wide tenant shell
- `AppRoute.portal` is the entry for choosing tenant-level features.
- Portal pages exist only for non-wide tenant navigation.
- Feature root pages may still use feature-local bottom-nav shells where that feature already does so.
- Bottom nav is for **feature tabs** only, not global app navigation.

### Wide tenant shell
- Wide tenant navigation uses the shared left **NavigationRail** + content area.
- Content switches inside the rail shell rather than replacing the shell scaffold.
- **No back button** on wide tenant feature roots; the rail is the primary navigation.
- Profile header remains display-only; account/settings are destinations, not inline actions.

## Branch workspace navigation model
Branch workspace no longer follows the tenant portal/rail split.

Across **all breakpoints**, branch workspace uses:
- app bar
- hidden drawer opened from the leading menu button
- content area

Important branch-shell rules:
- branch workspace does **not** use `NavigationRail`, even on wide screens
- branch workspace does **not** use the old non-wide branch portal as its home shell
- shell-level notifications and connectivity live in the branch app bar
- branch destinations and branch-scoped device context live in the drawer
- `To tenant` hands off to the existing tenant-level UI/role-aware behavior

### Branch feature roots and tabs
- Branch features may still use feature-local tabs inside the branch shell.
- Current examples:
  - cash session
  - sale
  - attendance
- Those tabs are feature-local only; the branch drawer is the primary workspace navigation.

### Sale layout rule
- Below `large`, sale keeps the local `Sale / Cart / Fulfillment` tab model.
- At `large`, sale collapses the cart into the main sale workspace as a side panel.
- `/sale/cart` should normalize back to `/sale` on wide screens.

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
  - `AppWideNavigationRailShell` for wide **tenant** screens.
  - `BranchWorkspaceScaffold` for branch workspace chrome across all breakpoints.
  - `AppBottomNavShellScaffold` for tenant/mobile feature tabs where that shell still applies.
- Pages should not implement their own global navigation controls.
