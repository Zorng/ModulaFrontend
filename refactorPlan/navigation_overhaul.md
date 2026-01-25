# Navigation Overhaul Refactor Plan (Option B)

Goal: unify navigation under a single responsive shell (rail for wide, bottom tabs for mobile), remove role‑specific duplicate routes, and centralize destination selection without path prefix hacks.

## Scope (impact scan)
- `lib/core/routing/app_router.dart` (AppRoute enum + canonical paths)
- `lib/app.dart` (router tree + redirects/guards)
- `lib/core/widgets/navigation/*` (rail, bottom tabs, shell)
- Feature portals/cards (admin/cashier) that push role‑specific paths
- Any pages relying on old paths (orders, cash session, attendance, reports)
- Tests referencing old paths

## Constraints / Non‑negotiables
- Single canonical route per feature (role‑aware UI inside the page)
- One navigation shell; no role‑specific shell routing
- No `matchPrefixes` path hacks
- GoRouter only (no `Navigator.push` for pages)
- Must work across breakpoints (`docs/responsive_breakpoints.md`)

---

## Phase 0 — Inventory & Baseline
- [x] List all current routes and identify duplicates (admin/cashier variants)
- [x] List all navigation surfaces (rail, bottom tabs, portals, feature cards)
- [x] Identify current redirect/guard logic in `lib/app.dart`

### Route inventory (current)
| Group | Paths | Notes |
|---|---|---|
| Auth | `/login`, `/select-tenant` | tenant selection gating |
| Portals | `/portal/admin`, `/portal/cashier` | mobile-only portal pages |
| Menu (admin) | `/portal/admin/menu/*` | categories/modifiers/items routes |
| Inventory (admin) | `/portal/admin/inventory/*` | stock items/categories/journal |
| Staff (admin) | `/portal/admin/staff/*` | detail/form/add |
| Policy | `/portal/admin/policy/*` | cashier can view (read-only) despite admin path |
| Sale | `/sale`, `/sale/cart`, `/sale/orders`, `/sale/orders/detail`, `/sale/item`, `/sale/carts/*` | sale tab shell + detail pages |
| Cash session | `/portal/admin/session`, `/portal/cashier/session` | role‑specific duplicates |
| Attendance | `/portal/cashier/attendance` | cashier/manager |
| Attendance mgmt | `/portal/admin/attendance-management` | admin only |
| Reports | `/portal/x-report`, `/portal/admin/z-report` | X shared; Z admin only |
| Account | `/account`, `/settings` | role‑aware |
| Components | `/components` | dev-only |

### Duplicate / role‑specific paths (smell)
- Cash sessions: `/portal/admin/session` vs `/portal/cashier/session`
- Portals: `/portal/admin` vs `/portal/cashier` (feature cards only; content overlaps)
- Policy path under admin namespace but accessible by cashier
- X report path shared (`/portal/x-report`) but lives outside a canonical reports namespace

### Navigation surfaces (current)
- `PortalShell` (`lib/core/widgets/navigation/portal_shell.dart`) used by `AdminPortal` + `CashierPortal`
- `AppWideNavigationRailShell` (`lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart`) for wide screens
- `AppBottomNavShellScaffold` (`lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart`) for mobile
- Sale tabs: `SaleBottomNavShellPage` (`lib/features/sale/ui/view/sale_shell/*`)
- Menu tabs: `MenuBottomNavShellPage` (`lib/features/menu/ui/view/menu_shell/*`)
- Inventory tabs: `InventoryBottomNavShellPage` (`lib/features/inventory/ui/view/inventory_shell/*`)
- Feature cards in `AdminPortal` + `CashierPortal`

### Redirects / guards (current)
In `lib/app.dart`:
- Legacy alias: `/admin/portal/menu` → `/portal/admin/menu`
- Home for all roles → `/sale`
- Role guards:
  - Admin‑only: admin portal/menu, inventory, staff, admin cash session, z report, attendance management
  - Cashier/manager: attendance
  - Admin/cashier: policy, cashier cash session, X report
- Cashier portal allowed for cashier/admin

**Output:** route inventory table + duplication list ✅

---

## Phase 1 — Canonical Path Map
Define the canonical, role‑agnostic paths:

| Feature | Canonical Path | Notes |
|---|---|---|
| Sale | `/sale` | tab shell (sale/cart/orders) |
| Orders | `/sale/orders` | sub‑route of sale |
| Cash Session | `/cash/session` | role‑aware page |
| Attendance | `/attendance` | role‑aware page |
| Attendance Mgmt | `/attendance/manage` | admin-only subpage |
| X Report | `/reports/x` | role‑aware page |
| Z Report | `/reports/z` | admin-only |
| Policy | `/policy` | role‑aware read-only for cashier |
| Inventory | `/inventory` | admin-only |
| Menu | `/menu` | admin-only |
| Staff | `/staff` | admin-only |
| Account | `/account` | role‑aware |

### Old → New mapping (phase 1)
| Old path | New canonical path | Notes |
|---|---|---|
| `/portal/admin` | `/sale` | portal removed in nav shell (mobile-only entry point) |
| `/portal/cashier` | `/sale` | portal removed in nav shell (mobile-only entry point) |
| `/portal/admin/menu` | `/menu` | admin only |
| `/portal/admin/menu/*` | `/menu/*` | keep same sub‑routes under `/menu` |
| `/portal/admin/inventory` | `/inventory` | admin only |
| `/portal/admin/inventory/*` | `/inventory/*` | keep sub‑routes |
| `/portal/admin/staff` | `/staff` | admin only |
| `/portal/admin/staff/*` | `/staff/*` | keep sub‑routes |
| `/portal/admin/policy` | `/policy` | role‑aware (cashier read‑only) |
| `/portal/admin/policy/*` | `/policy/*` | keep sub‑routes |
| `/portal/admin/session` | `/cash/session` | role‑aware cash session |
| `/portal/cashier/session` | `/cash/session` | role‑aware cash session |
| `/portal/cashier/attendance` | `/attendance` | role‑aware attendance |
| `/portal/admin/attendance-management` | `/attendance/manage` | admin only |
| `/portal/x-report` | `/reports/x` | role‑aware |
| `/portal/admin/z-report` | `/reports/z` | admin only |
| `/orders` | `/sale/orders` | already normalized |
| `/orders/detail` | `/sale/orders/detail` | already normalized |

**Output:** final canonical path table + mapping of old → new ✅

---

## Phase 2 — Router Refactor
- [x] Update `AppRoute` enum + path map
- [x] Update `lib/app.dart` router tree to canonical paths
- [x] Add **temporary redirects/aliases** from old paths to new (to avoid broken deep links)
- [x] Update guard logic to canonical path checks

**Output:** router compiles, old routes redirect ✅

---

## Phase 3 — Navigation Shell Refactor
- [x] Create **NavDestination map** (single source of truth)
- [x] Implement `AppScaffoldShell` (rail only; mobile bottom nav pending)
- [x] Selection state resolved via canonical path
- [x] Remove role-specific nav destinations
- [x] Account route included in nav map (no special casing)

**Output:** rail & bottom tabs driven by the same destination list

---

## Phase 4 — Update Entry Points
- [x] Update feature cards in portals to use canonical paths
- [x] Update any direct `context.go/ push` usages with old paths
- [x] Update tab shells (sale/menu/inventory) to match canonical paths

**Output:** all navigation uses canonical paths

---

## Phase 5 — Cleanup & Tests
- [x] Remove legacy role‑specific routes
- [x] Remove temporary redirects (after validation)
- [ ] Fix/adjust tests to canonical paths
- [ ] Run `flutter analyze` + `flutter test`

---

## Phase 6 — QA / Validation
Manual checklist (Admin + Cashier, Mobile + Wide):
- [ ] Login → default destination is Sale
- [ ] Rail selection updates correctly
- [ ] Profile/account does not break selection
- [ ] Branch switch keeps nav shell intact
- [ ] Sale tabs: Sale → Cart → Orders
- [ ] Cash session, attendance, X/Z report access respected by role
- [ ] Deep links redirect correctly

---

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Inventory/duplication/guards documented |
| 1 | Complete | Canonical map + old→new mapping |
| 2 | Complete | Router paths + redirects + guards updated |
| 3 | In progress | Nav map + rail refactor done; mobile bottom nav pending |
| 4 | Complete | Verified portal entry points + tab shells already on canonical paths |
| 5 | In progress | Legacy routes + redirects removed; tests pending |
| 6 | Not started |  |

---

## Decisions Log
- Option B (single AppScaffoldShell) selected
- Canonical path map required (no role‑specific duplicates)
- Account included in nav map
- Portal pages are **mobile-only feature launchers**; wide screens redirect `/portal/*` → `/sale`
