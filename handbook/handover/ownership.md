# Ownership Map

Purpose: make it obvious who owns what, who reviews what, and where to escalate.

## How to use
- If you touch a module listed here, ask the primary owner for review.
- If you touch a cross-cutting area, follow the escalation path.
- Keep this file updated when responsibilities change.

## Module ownership

| Area | Scope | Primary Owner | Backup Owner | Notes |
|---|---|---|---|---|
| Auth | `lib/features/auth/**` | TBD | TBD | Login, tenant selection, session storage |
| Cash session | `lib/features/cash_session/**` | TBD | TBD | Session open/close, X/Z report entry points |
| Reporting | `lib/features/reporting/**` | TBD | TBD | X/Z report APIs + mapping |
| Sale | `lib/features/sale/**` | TBD | TBD | Menu browsing, carts, checkout, policy + cash-session gating |
| Menu | `lib/features/menu/**` | TBD | TBD | Categories, items, modifiers, image upload |
| Inventory | `lib/features/inventory/**` | TBD | TBD | Stock items, restock, journal, on-hand |
| Policy | `lib/features/policy/**` | TBD | TBD | Policy hydration + editing UI |
| Staff | `lib/features/staff/**` | TBD | TBD | Staff profiles + shift schedule |
| Staff attendance | `lib/features/staff_attendance/**` | TBD | TBD | Check-in/out + attendance management |

## Cross-cutting ownership

| Area | Scope | Primary | Backup | Notes |
|---|---|---|---|---|
| Routing | `lib/core/routing/**`, `lib/app.dart` | TBD | TBD | `go_router` routes, path conventions |
| Network | `lib/core/network/**` | TBD | TBD | Dio headers, auth token, base URL |
| Hydration | `lib/core/hydration/**` | TBD | TBD | Session/tenant/branch changes triggering refresh |
| Shared widgets | `lib/core/widgets/**` | TBD | TBD | Promote only after 2+ feature usage |
| Logging/Errors | `lib/core/logging/**`, `lib/core/feedback/**` | TBD | TBD | Debug vs production error behavior |
| Theming/Responsive | `lib/core/theme/**`, `docs/responsive_breakpoints.md` | TBD | TBD | Breakpoints + wide-screen rules |

## Escalation path (default)
1) Module primary owner
2) Backup owner
3) Tech lead / maintainer (TBD)

## Optional: GitHub CODEOWNERS (automation)
If/when GitHub usernames/teams are finalized, we can add `.github/CODEOWNERS` to auto-request reviews.
Keep this file as the source-of-truth; CODEOWNERS is a convenience layer.
