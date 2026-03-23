# Branch Workspace Drawer Redesign

Goal: replace branch-workspace rail pressure with a drawer-based shell so branch operations have more usable space, while keeping operational status visible and consistent across the app.

This plan is the implementation-oriented follow-up to:
- [shellStatusAndSaleLayoutRework.md](/Users/mac/flutterProjects/modular/refactorPlan/shellStatusAndSaleLayoutRework.md)

## Locked Direction

### 1) Branch workspace uses drawer-based shell

For branch workspace, the target shell is:
- app bar
- drawer
- content area

Not target:
- persistent wide `NavigationRail` for branch workspace

Tenant workspace can remain on its existing navigation model unless later refactored separately.

Important lock:
- tenant workspace keeps its existing tenant navigation behavior
  - portal on non-wide
  - rail on wide
- branch workspace uses drawer-based navigation on **all** breakpoints
- branch drawer is a **hidden drawer**
- branch drawer entry lives in the **leading slot of the branch app bar**

So the workspace rule is:
- tenant workspace: existing portal/rail model
- branch workspace: app-bar + hidden drawer model

This is intended to reduce the current cognitive ambiguity where users need to infer whether they are in tenant or branch context from similar shell structures.

### 2) Operational signal ownership

Shell-level, always visible:
- notifications
- connectivity

Branch-scoped:
- devices / peripherals

Practical UI implication:
- notifications + connectivity belong in shared shell chrome
- devices belong in the branch drawer
- critical device warnings may still surface in branch app bar if needed, but device management/details stay drawer-scoped

### 3) Current proposed drawer information architecture

Current proposed branch drawer structure:

1. top workspace profile section
   - tenant
   - branch
2. `To tenant` text action
3. branch destinations
   - cash session
   - sale
   - policy
   - active discount
   - device management

Important behavior lock:
- `To tenant` should hand off to the **existing** tenant-level UI and role-aware behavior
- we are not redesigning tenant workspace as part of this drawer change
- current expected tenant behavior remains:
  - owner/admin: tenant management navigation/options
  - staff: available branches only

### 4) Device warning treatment is deferred

Device management stays in the branch drawer.

Possible critical device-warning treatment in the app bar is still intentionally deferred.

We should evaluate that later after the drawer shell exists, instead of locking a warning pattern too early.

### 3) Content width should be intentional

Removing branch rail frees width, but not every page should stretch infinitely.

So this redesign also adopts a width-governance rule:
- task-dense operational pages may use broader/full layouts
- read-heavy or form-heavy pages should use max-width containers

Sale is the main beneficiary of the regained width, but not every branch feature should become edge-to-edge by default.

### 4) Sale no longer has a separate medium navigation/layout mode

Locked sale direction:
- below `large`:
  - cart remains a tab
- at `large`:
  - cart becomes side view

So sale should not invent a separate `medium` cart/layout pattern.

## Problem This Solves

### A) Branch operations need more horizontal space

The current branch shell competes with operation UIs for width.

This hurts:
- sale
- cash session
- other branch operational screens

The most obvious pain is sale, where shell space and feature navigation structure currently fight each other.

### B) Operational state is not integrated cleanly

Notifications and sync/connectivity currently behave like overlays/add-ons rather than core shell information.

Drawer-based branch shell gives us a cleaner shared app bar structure for:
- notification access
- connectivity status
- optional critical operational warnings

### C) Middle-breakpoint sale hierarchy is still awkward

The sale feature currently has a layout conflict around the `medium` breakpoint:
- shell navigation pressure
- sale-internal cart/tab structure

Branch drawer is expected to reduce shell pressure so the sale workspace can be redesigned more intentionally.

## Scope

- branch workspace shell/chrome
- branch app bar
- branch drawer information architecture
- sale layout implications from regained width
- width-governance wrappers for branch pages that should not stretch

Primary files likely affected later:
- `lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart`
- `lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart`
- `lib/core/widgets/navigation/portal_shell.dart`
- `lib/core/widgets/navigation/app_navigation_config.dart`
- branch feature shell pages
- sale shell/layout files

## Non-Goals

This plan does not yet implement:
- tenant-level notification contract cutover
- final notification inbox redesign
- full tenant workspace navigation redesign
- device management feature expansion

This plan also does not assume every branch page uses the same width strategy.

## Design Rules

### Rule 1 — One branch shell model

Branch workspace should not present itself as:
- rail shell on one breakpoint
- different structural navigation paradigm on another breakpoint

The branch drawer model should define the branch shell consistently, with breakpoint-specific sizing and behavior rather than different navigation metaphors.

Practical interpretation:
- we still keep the global breakpoint system from [responsive_breakpoints.md](/Users/mac/flutterProjects/modular/docs/responsive_breakpoints.md)
- but for **branch navigation**, `medium` should behave like the drawer path rather than introducing a separate branch-shell navigation model
- so branch shell behavior should feel like:
  - `small + medium` -> hidden drawer navigation
  - `large` -> hidden drawer navigation with wider content opportunities, not branch rail

### Rule 2 — Shell signals must be scannable

The app bar under branch workspace should support:
- notification access
- connectivity visibility

These must remain easy to find regardless of current branch page.

### Rule 3 — Drawer holds branch operations/support context

The drawer should be the home for:
- branch destinations
- device/peripheral context
- `To tenant` handoff action
- branch-specific support actions if needed

It should not become a junk drawer of unrelated app/global actions.

### Rule 4 — Width is governed, not accidental

After removing the branch rail:
- sale may expand more aggressively
- other pages should use max-width containers where appropriate

The absence of rail must not become an excuse for stretched layouts.

## Phase Plan

## Phase 0 — Inventory And Lock Current Branch Surfaces
- [x] List current branch-workspace destinations
- [x] List current branch shell entry points across breakpoints
- [x] Identify where notification/connectivity currently render
- [x] Identify which branch pages currently rely on wide rail assumptions

Output:
- inventory of branch shell surfaces and branch feature roots

### Phase 0 Findings

#### 1) Current branch-workspace destinations

Source:
- [app_navigation_config.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_navigation_config.dart)

Current branch-layer destination sets are:

Owner/Admin branch layer:
- `Cash Sessions`
- `Policy`
- `Sale`
- `Active Discount`

Manager/Cashier/Staff branch layer:
- `Cash Sessions`
- `Sale`
- `Active Discount`
- `Attendance`
- `Attendance Management` for manager only

Important gap:
- `Device Management` does **not** exist yet as a real branch destination in the current navigation config
- so drawer IA already includes one net-new destination that will need routing/surface definition during implementation

#### 2) Current branch shell entry behavior

Sources:
- [branch_selection_page.dart](/Users/mac/flutterProjects/modular/lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart)
- [app.dart](/Users/mac/flutterProjects/modular/lib/app.dart)
- [portal_routes.dart](/Users/mac/flutterProjects/modular/lib/core/routing/routes/portal_routes.dart)

Current behavior:
- after branch selection:
  - `large` -> go directly to [cash session](/Users/mac/flutterProjects/modular/lib/core/routing/app_router.dart)
  - below `large` -> go to [branch portal](/Users/mac/flutterProjects/modular/lib/core/routing/app_router.dart)
- admin/owner home:
  - `large` with active branch -> `cash session`
  - `large` without active branch -> `branches`
  - below `large` -> `portal`
- non-admin branch users home:
  - with active branch:
    - `large` -> `cash session`
    - below `large` -> `branch portal`

Current result:
- branch workspace uses **two different shell entry metaphors**
  - wide direct-entry feature root
  - non-wide branch portal hub

That is one of the exact inconsistencies this redesign is meant to remove.

#### 3) Current notification / sync / connectivity rendering

Sources:
- [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
- [portal_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/portal_shell.dart)
- [app_bottom_nav_shell_scaffold.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart)

Current state:
- `Notifications`
  - shown in wide shell top-right overlay
  - shown in portal shell app bar
  - shown in feature bottom-shell app bars
- `Sync`
  - shown only in wide shell top-right overlay
- `Connectivity`
  - not presented as first-class shell status yet

Important result:
- shell-level operational status is currently inconsistent by breakpoint/shell type
- notifications already behave like shared shell chrome
- sync/connectivity do not yet have a consistent shared shell treatment

#### 4) Current branch-scoped path assumptions

Sources:
- [app.dart](/Users/mac/flutterProjects/modular/lib/app.dart)
- [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)

The app currently treats these as branch-scoped groups:
- `branchPortal`
- `cashSession`
- `cashHistory`
- `policy`
- `notifications`
- `sale`
- `active discount`
- `attendance`
- `x/z report`
- `attendanceManagement`

This matters because the existing wide rail shell and route guards still assume branch workspace is a rail-class navigation layer.

#### 5) Current branch pages most coupled to the old shell split

High-impact pages/features:
- `Sale`
  - [sale_bottom_nav_shell_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart)
  - below `large`: uses bottom-tab shell with back to `branchPortal`
  - `large`: uses side cart layout and bypasses branch portal
- `Policy`
  - [policy_page.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/view/policy/policy_page.dart)
  - still carries portal-era back/navigation assumptions
- `Active Discount`
  - [discount_page.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/view/discount/discount_page.dart)
  - branch-active variant still has explicit back behavior tied to current shell split
- `Portal branch cards`
  - [app_navigation_portal_content.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_navigation_portal_content.dart)
  - this is the current non-wide branch entry surface that drawer cutover is expected to replace

#### 6) Current device/peripheral surface

There is no current branch-level device management destination.

Closest existing device-related surface:
- sale printer status action/dialog in
  - [sale_printer_status_action.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_shell/widgets/sale_printer_status_action.dart)

Implication:
- drawer `Device Management` is not a move-only task
- it will require either:
  - a new destination/screen, or
  - a promoted/reframed device surface derived from current printer/device status work

## Phase 1 — Branch Drawer Contract
- [x] Define branch app bar responsibilities
- [x] Define drawer contents and grouping
- [x] Define which elements stay outside the drawer:
  - notifications
  - connectivity
  - possible critical device warning only
- [x] Define breakpoint behavior for drawer interaction

Output:
- locked branch shell contract

### Phase 1 Contract

#### 1) Branch app bar responsibilities

Branch workspace app bar is now responsible for:
- leading:
  - hidden drawer trigger
- title area:
  - current branch page title
- trailing shell-level status/actions:
  - connectivity
  - notifications
- trailing page-level actions:
  - still allowed, but they must not replace the shell-level status/actions

Important implication:
- notifications and connectivity are part of the branch shell chrome, not per-page optional UI
- page actions must coexist with them rather than redefine the app bar structure per page

#### 2) Branch drawer contents and grouping

Locked drawer information architecture:

Top section:
- current workspace profile
  - tenant
  - branch

Context handoff:
- `To tenant`
  - hands off to the existing tenant-level UI and role-aware behavior

Branch destination section:
- cash session
- sale
- policy
- active discount
- attendance / attendance management where role allows

Device section:
- device management
  - still a new surface to be defined during implementation

Important:
- account/settings are not being redesigned as part of this drawer contract
- tenant workspace behavior remains unchanged

#### 3) What stays outside the drawer

Outside the branch drawer:
- notifications
- connectivity

Still deferred:
- whether a critical device warning also appears in the branch app bar

So the drawer is for:
- branch navigation
- branch support context

Not for:
- global shell-status signals

#### 4) Breakpoint behavior for branch drawer interaction

Locked branch-shell behavior:
- `small`
  - hidden drawer from app-bar leading
- `medium`
  - hidden drawer from app-bar leading
- `large`
  - hidden drawer from app-bar leading

So branch workspace no longer changes navigation metaphor by breakpoint.

#### 5) Branch workspace entry behavior

Because branch drawer replaces branch portal as the non-wide branch shell:
- branch workspace should no longer enter through a separate portal-style hub on non-wide
- branch entry should converge on the branch default feature root instead

Current intended default branch root remains:
- `Cash Session`

Practical implication for later implementation:
- branch selection / branch-switch flows should target branch feature root consistently
- current `branchPortal` dependency should be removed from branch workspace entry flow

## Phase 2 — Width Governance Rules
- [x] Identify branch pages that should use max-width containers
- [x] Identify branch pages that should use broader/full-width layouts
- [x] Lock rules for:
  - sale
  - cash session
  - policy
  - other branch operational/detail pages

Output:
- branch page width matrix

### Phase 2 Findings

#### 1) Sale should remain the main full-width beneficiary

Source:
- [sale_bottom_nav_shell_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart)

Current behavior already points the right way:
- below `large`
  - bottom-tab workspace
- at `large`
  - content row + side cart panel

Width conclusion:
- `Sale` should stay the main branch page that uses the regained width most aggressively
- no additional root max-width wrapper should be introduced around sale
- Phase 3 should refine sale internals, but Phase 2 locks that sale is a broad/full-width page

#### 2) Cash Session root should stay broad on wide screens

Source:
- [cashier_cash_session.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/cash_session/cashier_cash_session.dart)

Current wide layout uses:
- overview / summary
- action card
- session sales section

Width conclusion:
- `Cash Session` is an operational dashboard, not a form page
- it should keep a broad layout on wide screens
- normal content padding is enough; do not clamp it to a narrow max-width container

#### 3) Cash history and attendance review are wide-data pages

Sources:
- [cash_session_history_page.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/cash_history/cash_session_history_page.dart)
- [staff_attendance_review_tab_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff/ui/view/staff_attendance_review/staff_attendance_review_tab_page.dart)

Current behavior:
- cash history wide mode uses a session list table and wide detail flow
- attendance review wide mode switches to a data table

Width conclusion:
- these pages should remain broad on wide screens
- they are table/data-review surfaces and benefit from horizontal space
- they should use page padding, not a narrow max-width clamp

#### 4) Policy and operator attendance should be capped

Sources:
- [policy_page.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/view/policy/policy_page.dart)
- [attendance_check_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_check/attendance_check_page.dart)
- [attendance_history_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_history/attendance_history_page.dart)

Current behavior:
- these pages are mostly single-column, read-heavy, or action-card flows
- they currently rely mostly on padding, not a real width cap

Width conclusion:
- `Policy`, `Attendance Check`, and `Attendance History` should use explicit max-width containers
- these are not pages that become better by stretching edge-to-edge after the rail is removed
- target feel should be centered, readable, and intentionally bounded

#### 5) Active Discount should stay bounded, not edge-to-edge

Source:
- [discount_page.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/view/discount/discount_page.dart)

Current behavior already constrains content:
- large branch-active/management layout uses bounded content widths
- read-only active discount is card-based rather than table-dense

Width conclusion:
- `Active Discount` should remain a bounded page
- it can use a wider cap than policy/attendance, but it should not become full-width by default
- this aligns with its operator-summary role

#### 6) X/Z report pages should use moderate caps

Sources:
- [x_report_page.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/x_report/x_report_page.dart)
- [z_report_page.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/z_report/z_report_page.dart)

Current behavior:
- both are card/filter-driven, not workspace-style operational canvases
- `Z Report` in particular is essentially a focused single-card flow

Width conclusion:
- `X Report` and `Z Report` should use bounded widths
- they do not need the same breadth as sale, cash session, or wide data-table pages

### Phase 2 Width Matrix

| Branch page / surface | Width rule | Notes |
|---|---|---|
| Sale | Broad / full width | Main beneficiary of rail removal; keep large side-cart layout |
| Cash Session | Broad / full width | Operational dashboard with multi-panel layout |
| Cash History | Broad on wide | Table/list surface benefits from width |
| Attendance Management | Broad on wide | Wide mode uses data table |
| Policy | Max-width | Read-heavy and settings-oriented |
| Active Discount | Max-width (wider cap) | Card-based summary surface, not edge-to-edge |
| Attendance Check | Max-width | Single-column operational action flow |
| Attendance History | Max-width | Narrow list/history reading surface |
| X Report | Max-width (moderate) | Filter + card list, not a dashboard |
| Z Report | Max-width (moderate) | Focused single-card flow |

### Phase 2 Lock

Implementation rule:
- broad/full-width branch pages:
  - `Sale`
  - `Cash Session`
  - `Cash History`
  - `Attendance Management`
- bounded/max-width branch pages:
  - `Policy`
  - `Active Discount`
  - `Attendance Check`
  - `Attendance History`
  - `X Report`
  - `Z Report`

Practical implication for later implementation:
- width governance should be applied with feature-level wrappers, not ad hoc card-by-card fixes
- rail removal alone is not considered a successful layout outcome until bounded pages are visually stabilized

## Phase 3 — Sale Layout Follow-Through
- [x] Reassess sale after branch rail removal
- [x] Decide how cart behaves at:
  - `small`
  - `medium`
  - `large`
- [x] Ensure sale no longer feels like shell nav and feature nav are competing

Output:
- sale layout cutover plan under drawer-based branch shell
- locked sale behavior:
  - `small + medium` -> cart tab
  - `large` -> side cart

### Phase 3 Findings

#### 1) Sale currently duplicates shell responsibilities that should move up

Sources:
- [sale_bottom_nav_shell_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart)
- [app_bottom_nav_shell_scaffold.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart)

Current behavior:
- below `large`, sale uses [AppBottomNavShellScaffold](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart)
  - app bar title
  - back-to-home button
  - notification bell
- at `large`, sale builds its own `AppBar`
  - title
  - page actions
  - no branch drawer entry

Conflict with new shell contract:
- branch shell app bar is supposed to own:
  - leading drawer trigger
  - page title
  - shell-level connectivity
  - shell-level notifications

Sale conclusion:
- sale should stop owning branch-shell app bar behavior
- sale should become a content/workspace surface inside the branch shell, not a second shell

#### 2) Current sale route model is coherent below `large`, but not at `large`

Source:
- [sale_routes.dart](/Users/mac/flutterProjects/modular/lib/core/routing/routes/sale_routes.dart)

Current sale route tree:
- `/sale`
- `/sale/cart`
- `/sale/orders`

Current layout behavior:
- below `large`
  - three-tab workspace
    - `Sale`
    - `Cart`
    - `Fulfillment`
- at `large`
  - cart is no longer a real tab in the UI
  - wide bottom nav only shows:
    - `Sale`
    - `Fulfillment`
  - cart becomes side panel when sale tab is active

Important inconsistency:
- `/sale/cart` remains a real branch in the route tree even though wide layout conceptually replaces it with a side panel

Sale conclusion:
- below `large`, `Cart` remains a real workspace tab
- at `large`, cart stops being a first-class sale destination and becomes part of the `Sale` workspace
- the large-screen canonical route for cart state should be `/sale`, not `/sale/cart`

#### 3) Sale should no longer use “back to branch portal”

Sources:
- [sale_bottom_nav_shell_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart)
- [app.dart](/Users/mac/flutterProjects/modular/lib/app.dart)

Current behavior:
- non-wide sale still exposes a home/back affordance to `branchPortal`

Conflict with new branch-shell direction:
- branch portal is no longer the intended non-wide branch shell
- branch navigation should happen through the drawer, not through a feature-local back button to a hub page

Sale conclusion:
- sale should not retain a `branchPortal` back path in the cutover design
- the drawer becomes the branch navigation escape hatch

#### 4) Sale still needs internal workspace navigation, but it must read as feature-local

Current need:
- sale has more than one operational workspace:
  - selling/catalog
  - cart
  - fulfillment

Locked interpretation:
- branch drawer is the primary branch/workspace navigation
- sale workspace switching is secondary, feature-local navigation

Practical implication:
- below `large`
  - bottom tabs are acceptable because screen space is constrained and cart remains a real tab
- at `large`
  - feature switching should not read like a second app-level bottom nav
  - sale should use a lighter secondary workspace switcher for:
    - `Sale`
    - `Fulfillment`
  - `Cart` is represented by the side panel, not by a third wide nav destination

### Phase 3 Lock

Sale cutover rules:

1. App bar ownership
- branch shell owns the app bar
- sale should not build its own branch-shell app bar after cutover

2. Non-wide sale behavior (`small + medium`)
- sale keeps internal bottom tabs:
  - `Sale`
  - `Cart`
  - `Fulfillment`
- cart remains a real route/destination below `large`

3. Wide sale behavior (`large`)
- `Sale` workspace uses:
  - menu/catalog content
  - persistent side cart panel
- `Fulfillment` remains a separate sale workspace
- `Cart` is no longer a peer top-level sale destination on wide screens
- `/sale/cart` should normalize to `/sale` on wide screens during implementation

4. Navigation hierarchy
- branch drawer = primary branch navigation
- sale workspace switcher = secondary feature navigation
- feature navigation should not visually impersonate the app shell on wide screens

5. Back/hub behavior
- sale should not navigate back to `branchPortal`
- branch-level leaving/navigation is handled by the drawer

Practical implication for implementation:
- [sale_bottom_nav_shell_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart) will need to be refactored away from the current mixed shell responsibilities
- the sale route tree may stay structurally similar below `large`, but wide behavior should collapse cart into the sale root workspace

## Phase 4 — Shell Implementation
- [x] Implement branch drawer shell
- [x] Move branch-scoped navigation into drawer
- [x] Move device section into drawer
- [x] Keep notification/connectivity in shared shell chrome

Output:
- functioning drawer-based branch shell

### Phase 4 Implementation Notes

What landed:
- a shared branch app-bar + hidden drawer scaffold
- branch destination drawer built from the existing role-aware branch navigation config
- `To tenant` handoff wired to the existing tenant/branch-selection behavior
- shell-level status/actions moved into branch app bars:
  - notifications
  - sync/connectivity status pill
- branch entry and old `branchPortal` behavior shifted toward `cash session` as the branch root

Current practical state:
- branch root screens now use the drawer shell instead of relying on branch portal / branch-wide rail assumptions
- tenant workspace behavior remains unchanged
- device section exists in the drawer as a placeholder support surface until dedicated device management lands

Important boundary:
- sale wide-shell polish is only partially realized in this phase
- the branch shell is now in place, but Phase 5 still owns the remaining layout stabilization and feature-level width cleanup

## Phase 5 — Width And Feature Cutover
- [x] Apply max-width wrappers where needed
- [x] Rebalance sale layout with regained width
- [x] Validate branch pages for awkward stretching

Output:
- branch features visually stabilized under new shell

### Phase 5 Implementation Notes

What landed:
- a shared bounded-content frame in
  - [bounded_content_frame.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/layout/bounded_content_frame.dart)
- bounded branch page bodies now use that frame:
  - [policy_page.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/view/policy/policy_page.dart)
  - [attendance_check_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_check/attendance_check_page.dart)
  - [attendance_history_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_history/attendance_history_page.dart)
  - [staff_attendance_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff/ui/view/staff_attendance/staff_attendance_page.dart)
  - [x_report_page.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/x_report/x_report_page.dart)
  - [z_report_page.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/z_report/z_report_page.dart)
- branch active discounts now use a bounded wide cap instead of stretching across the full large-screen shell in
  - [discount_page.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/view/discount/discount_page.dart)

Practical result:
- bounded branch pages now center and cap cleanly under the drawer shell
- wide sale remains the broad layout exception with its side cart, while operator/read-heavy pages no longer inherit the full shell width accidentally
- shell-level route/tests covering the new drawer plus attendance/discount bounded pages stayed green after the width cutover

## Phase 6 — Validation And Docs
- [x] Update relevant navigation/responsive docs
- [x] Add/refresh shell/navigation widget tests
- [x] Document manual QA on:
  - branch workspace
  - sale `medium`
  - sale `large`
  - cash session
  - policy

### Phase 6 Notes

Docs updated:
- [handbook/architecture/navigation.md](/Users/mac/flutterProjects/modular/handbook/architecture/navigation.md)
  - now distinguishes tenant workspace shell rules from branch workspace shell rules
  - records branch workspace as drawer-based across all breakpoints
  - records sale's non-wide tab vs wide side-cart rule
- [docs/responsive_breakpoints.md](/Users/mac/flutterProjects/modular/docs/responsive_breakpoints.md)
  - now reflects workspace-aware navigation behavior instead of treating wide screens as universally rail-based

Validation footprint captured:
- shell/navigation widget tests refreshed earlier in Phases 4 and 5:
  - [workspace_navigation_widgets_test.dart](/Users/mac/flutterProjects/modular/test/core/navigation/workspace_navigation_widgets_test.dart)
  - [discount_pages_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_pages_test.dart)
  - [discount_route_access_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_route_access_test.dart)
- bounded attendance pages also stayed green after the width cutover:
  - [attendance_check_page_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_check_page_test.dart)
  - [attendance_history_page_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_history_page_test.dart)

Recommended manual QA checklist before merge:
1. Branch workspace
   - enter a branch from tenant UI
   - confirm branch shell shows app bar + leading drawer, not portal/rail
   - confirm `To tenant` returns to the existing tenant behavior for the current role
2. Sale `medium`
   - confirm sale still uses feature tabs
   - confirm cart is still a tab and not a side panel
3. Sale `large`
   - confirm sale uses the branch drawer shell
   - confirm the cart is rendered as a side panel and `/sale/cart` normalizes back to `/sale`
4. Cash session
   - confirm branch drawer navigation works across `Session / Movement / History`
   - confirm the shell app bar remains stable while feature-local tabs change
5. Policy
   - confirm the page is visually centered/bounded under the drawer shell
   - confirm narrow and wide layouts do not stretch awkwardly

Important note:
- this phase documents the manual QA checklist; it does not claim that a human browser/device pass has already been executed in this turn

## Open Questions

- Which max-width caps should we standardize first?
  - compact/narrow content cap
  - wider bounded content cap

This no longer blocks shell implementation, but it should be answered before the width cutover phase lands.

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Inventory locked: role-based branch destinations, wide vs non-wide branch entry split, inconsistent notification/sync surfaces, no existing device-management destination |
| 1 | Complete | Branch shell contract locked: app-bar leading drawer, shell-level notifications/connectivity, `To tenant` handoff, branch portal no longer the intended non-wide branch shell |
| 2 | Complete | Width matrix locked: sale/cash session/history/attendance review stay broad, while policy/active discount/attendance operator pages/x-z reports should be bounded |
| 3 | Complete | Sale cutover locked: shell app bar moves up to branch shell, non-wide keeps 3 sale tabs, wide collapses cart into sale root with side panel and no branch-portal back path |
| 4 | Complete | Shared branch drawer shell landed, branch routes now use drawer/app-bar chrome, shell status moved into app bars, branch entry shifted toward cash session root |
| 5 | Complete | Added shared bounded-content frame, applied it to policy/attendance/reports, and capped branch active-discount wide layout so bounded pages no longer stretch under the drawer shell |
| 6 | Complete | Navigation and breakpoint docs updated to reflect tenant-vs-branch shell behavior, validation footprint recorded, and manual QA checklist documented for branch workspace + sale/cash/policy follow-through |
