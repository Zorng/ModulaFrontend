# Tenant Shell Account Utility Refactor

Goal: simplify tenant-shell utility chrome by replacing separate account/settings/logout controls with one consistent account entry, while upgrading the account surface so both admin and staff retain reliable access to session utilities.

## Problem Statement

The current tenant-level utility IA is fragmented:
- notifications and connectivity now occupy more of the shell action area
- some tenant screens still expose standalone `Settings` / `Log out` actions in app-bar chrome
- `Account` exists as a route, but it is currently too thin to act as the main utility hub

This creates two problems:

1. Shell crowding
- utility actions compete for the same top-right action area
- this has already created overlap/blocking risk in tenant workspace

2. Inconsistent access model
- owner/admin can naturally absorb utility movement into tenant navigation more easily
- staff cannot, because their tenant UI is mostly branch-entry focused
- so `Account` cannot be treated as tenant navigation only

## Current State Inventory

Current surfaces involved:
- tenant selection app bar
  - [tenant_selection_page.dart](/Users/mac/flutterProjects/modular/lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart)
- tenant/non-wide portal shell
  - [portal_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/portal_shell.dart)
- tenant/wide rail shell
  - [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
- account route/page
  - [account_routes.dart](/Users/mac/flutterProjects/modular/lib/core/routing/routes/account_routes.dart)
  - [account_page.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/account_page.dart)
- settings route/page
  - [settings_page.dart](/Users/mac/flutterProjects/modular/lib/features/common/ui/settings_page.dart)

Current account-page composition:
- identity summary
- branch list
- two placeholder actions
- logout button

Assessment:
- `Account` exists, but is not yet a true utility hub
- `Settings` exists, but is too lightweight to justify shell prominence

## Target Direction

### 1) One universal account entry in shell chrome

Keep a single compact `Account` entry in shared shell chrome:
- tenant workspace
- branch workspace
- all roles

Preferred representation:
- avatar or person icon

This account affordance should be the only non-operational utility entry in the shell action area.

### 2) Shell chrome responsibilities

Shell action area should contain:
- notifications
- connectivity / sync
- account

Shell action area should not contain separate:
- settings button
- logout button

### 3) Account becomes the utility hub

The `Account` surface should absorb:
- user/account summary
- memberships / branch access summary
- settings entry
- logout action

Settings remains a valid route, but becomes downstream of account rather than a first-class shell action.

### 4) Staff and admin must use the same access rule

Important lock:
- `Account` is not tenant-navigation-only
- `Account` must remain globally reachable from shell chrome

Reason:
- staff tenant UI is not a true feature/management navigation space
- staff still need a reliable path to account/session utilities

## Scope

- tenant-shell utility action cleanup
- shared shell account entry pattern
- account page information architecture
- settings entry relocation
- logout relocation

Likely files:
- `lib/core/widgets/navigation/portal_shell.dart`
- `lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart`
- `lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart`
- `lib/features/auth/ui/view/account/account_page.dart`
- `lib/features/auth/ui/view/account/widgets/*`
- `lib/features/common/ui/settings_page.dart`

## Non-Goals

This plan does not include:
- notification contract changes
- branch drawer IA changes
- device/peripheral UI changes
- full settings feature expansion

## Design Rules

### Rule 1 — Account is a utility surface, not a business destination

Do not model `Log out` as a rail destination or portal feature card.

Do not rely on tenant navigation alone to access account/session utilities.

The correct hierarchy is:
- shell account entry
- account surface
- settings and logout inside account/session area

### Rule 2 — Operational chrome stays operational

Top-right shell actions should prioritize:
- notification awareness
- connectivity/sync state

Utility/session controls should be collapsed under one account affordance.

### Rule 3 — Account must work for all roles

The solution must be equally reachable for:
- owner/admin
- manager/cashier/staff

No role should lose access to account/session utilities because of navigation-model differences.

## Phase Plan

## Phase 0 — Inventory And Lock Current Utility Surfaces
- [x] Inventory all current account/settings/logout entry points
- [x] Confirm which tenant and branch shells expose them today
- [x] Confirm current account/settings content and gaps

Output:
- current utility-entry map + current account-page assessment

### Phase 0 Findings

#### 1) Current utility entry points are fragmented by shell and role

Current entry surfaces:

- tenant selection app bar
  - [tenant_selection_page.dart](/Users/mac/flutterProjects/modular/lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart)
  - currently shows:
    - invitation inbox
    - settings icon
    - logout icon

- tenant/non-wide portal shell
  - [portal_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/portal_shell.dart)
  - supports:
    - notifications
    - sync/connectivity
    - optional account icon
    - optional settings icon

- tenant/wide rail shell
  - [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
  - currently shows:
    - notifications
    - sync/connectivity
  - it does **not** currently expose a dedicated account action in the shell chrome

- branch workspace shell
  - [branch_workspace_scaffold.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/branch_workspace_scaffold.dart)
  - currently shows:
    - notifications
    - sync/connectivity
    - page-specific actions only
  - it does **not** currently expose account/settings/logout

Result:
- there is no single universal account/session utility entry today
- utility access differs by surface and role instead of following one shell rule

#### 2) Portal behavior is inconsistent between admin and staff

Portal consumers:
- [admin_portal.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/portals/admin_portal.dart)
- [cashier_portal.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/portals/cashier_portal.dart)

Current behavior:
- admin portal only wires account/settings when rendered at branch layer
- admin tenant-layer portal does not expose account/settings
- cashier portal exposes neither account nor settings

Result:
- even within the portal shell, account utility access is role/layer dependent
- this confirms `Account` cannot be solved as tenant-navigation-only

#### 3) Account and settings routes already exist, but they are underpowered

Current routes:
- [account_routes.dart](/Users/mac/flutterProjects/modular/lib/core/routing/routes/account_routes.dart)

Current account page:
- [account_page.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/account_page.dart)

Current composition:
- user summary
- branch list
- placeholder action tiles in [account_action_tiles.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/widgets/account_action_tiles.dart)
- logout button

Current settings page:
- [settings_page.dart](/Users/mac/flutterProjects/modular/lib/features/common/ui/settings_page.dart)
- only contains lightweight placeholder settings

Result:
- `Account` is present but not yet a true utility hub
- `Settings` is too thin to justify separate shell prominence
- moving shell controls into `Account` will require a small account-page redesign, not just a button relocation

#### 4) Wide rail already treats account/settings as utility exceptions

In [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart):
- fallback rail selection is disabled for `account` and `settings`
- layer-back behavior is also special-cased for `account` and `settings`

This implies the current architecture already treats them differently from business destinations.

Result:
- promoting `Account` as a shell utility entry aligns with the existing routing behavior better than trying to force it into tenant business navigation

#### 5) Main gap to solve in later phases

The real problem is not only shell crowding.

It is the combination of:
- too many top-right utility actions on some tenant surfaces
- no universal account entry across all shells/roles
- an account page that is not yet strong enough to absorb settings/logout cleanly

So the next phase should lock:
- one shared account-entry rule
- shell action budget
- account-page responsibilities after relocation

## Phase 1 — Lock Utility IA
- [x] Lock shell action-area rule
- [x] Lock account placement rule
- [x] Lock settings/logout relocation rule
- [x] Lock whether account opens directly to page or via intermediate menu

Output:
- accepted utility IA contract

### Phase 1 Contract

#### 1) Shell action-area rule

Shared shell action area should prioritize:
- notifications
- connectivity / sync
- account

The shell action area should not expose separate:
- settings button
- logout button

Reason:
- those controls compete with operational chrome
- this is already causing crowding/overlap risk on tenant surfaces

#### 2) Account placement rule

`Account` is a universal shell utility entry.

Locked placement:
- shared app-bar action area
- tenant workspace
- branch workspace
- all roles

Preferred visual:
- compact person/avatar affordance

Important lock:
- `Account` is **not** being moved into tenant rail/portal navigation as the primary access rule for this refactor
- wide tenant rail may still eventually gain an account destination later if useful, but that is not the dependency for reliable access

Reason:
- staff do not have the same tenant navigation model as owner/admin
- a shell utility entry is the only placement that is role-agnostic and workspace-agnostic

#### 3) Settings / logout relocation rule

Locked relocation:
- remove standalone settings/logout from shell chrome
- move settings access under the account surface
- move logout under the account surface

Specific interpretation:
- `Settings` remains a route, but becomes downstream of `Account`
- `Logout` remains an action, not a destination
- do not model `Logout` as a rail item or portal feature card

#### 4) Account entry behavior

Locked behavior for this refactor:
- tapping the shell account affordance goes **directly to the account page**
- no intermediate account menu in this phase

Reason:
- the app already has a real `Account` route
- direct routing is simpler and more consistent than introducing a new transient utility menu
- the current problem is IA fragmentation, not lack of a menu

Implication:
- the account page must become strong enough to absorb:
  - settings entry
  - logout action
  - utility/session hierarchy

#### 5) Phase-2 design expectation

Because of the direct-to-page decision, the account page must be upgraded from:
- basic profile summary + placeholders

to:
- a true utility hub with clear sections for:
  - account/profile
  - memberships / branches
  - settings
  - session / logout

## Phase 2 — Account Surface Redesign
- [x] Restructure account page into clearer sections
- [x] Add explicit settings entry
- [x] Reposition logout into account/session section
- [x] Ensure current account content still fits both admin and staff

Output:
- account page is a viable utility hub

### Phase 2 Result

Implemented in:
- [account_page.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/account_page.dart)
- [account_user_tile.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/widgets/account_user_tile.dart)
- [account_membership_list.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/widgets/account_membership_list.dart)
- [account_action_tiles.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/view/account/widgets/account_action_tiles.dart)
- [settings_page.dart](/Users/mac/flutterProjects/modular/lib/features/common/ui/settings_page.dart)
- [policy_detail_controls.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/widgets/policy_detail_controls.dart)

What changed:
- `Account` now reads as a utility hub with clear sections for:
  - profile
  - access
  - settings
  - session
- access is now summarized from session memberships when available, with the current tenant called out explicitly
- settings now has an explicit navigable tile from the account surface
- logout now lives in a dedicated session section instead of as a detached page-bottom button
- account/settings utility pages no longer show the inherited no-op `Edit` affordance

Coverage:
- [account_page_test.dart](/Users/mac/flutterProjects/modular/test/auth/account_page_test.dart)
  - locks the sectioned account layout
  - locks settings navigation from account
  - locks removal of the bogus `Edit` action on account/settings utility pages

## Phase 3 — Shell Cleanup
- [x] Remove standalone settings/logout actions from tenant shell surfaces
- [x] Add/standardize the shared account entry in shell chrome
- [x] Keep notification/connectivity visible without overlap

Output:
- tenant shell utility chrome simplified and consistent

### Phase 3 Result

Implemented in:
- [account_shell_action.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/account_shell_action.dart)
- [portal_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/portal_shell.dart)
- [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
- [branch_workspace_scaffold.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/branch_workspace_scaffold.dart)
- [tenant_selection_page.dart](/Users/mac/flutterProjects/modular/lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart)
- [branch_selection_page.dart](/Users/mac/flutterProjects/modular/lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart)
- [admin_portal.dart](/Users/mac/flutterProjects/modular/lib/features/auth/ui/portals/admin_portal.dart)

What changed:
- added one shared shell-level account affordance via `AccountShellAction`
- tenant selection now shows:
  - invitation inbox
  - account
  and no longer shows standalone settings/logout buttons
- branch selection now shows:
  - account
  and no longer shows a standalone logout button
- portal shell now shows:
  - notifications
  - connectivity
  - account
  and no longer supports a separate settings action
- wide tenant rail now includes the same account affordance in its top-right shell action cluster
- branch workspace app bar now includes the same account affordance after the notification/connectivity indicators

Coverage:
- [workspace_navigation_widgets_test.dart](/Users/mac/flutterProjects/modular/test/core/navigation/workspace_navigation_widgets_test.dart)
  - locks account visibility on wide rail, branch shell, and tenant portal shell
- [tenant_selection_page_test.dart](/Users/mac/flutterProjects/modular/test/tenant/tenant_selection_page_test.dart)
  - locks tenant-selection app-bar action cleanup and account navigation
- [branch_selection_page_test.dart](/Users/mac/flutterProjects/modular/test/branch/branch_selection_page_test.dart)
  - locks branch-selection app-bar cleanup and account navigation

## Phase 4 — Validation
- [x] Add/refresh widget tests for tenant shell action visibility
- [x] Add/refresh account-page widget tests if needed
- [x] Manual QA across:
  - tenant selection
  - tenant portal
  - wide tenant rail
  - branch shell
  - staff and admin roles

### Phase 4 Result

Automated validation completed:
- `flutter analyze lib/core/widgets/navigation/account_shell_action.dart lib/core/widgets/navigation/portal_shell.dart lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart lib/core/widgets/navigation/branch_workspace_scaffold.dart lib/features/auth/ui/portals/admin_portal.dart lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart lib/features/auth/ui/view/account/account_page.dart lib/features/auth/ui/view/account/widgets/account_action_tiles.dart lib/features/auth/ui/view/account/widgets/account_branch_list.dart lib/features/auth/ui/view/account/widgets/account_membership_list.dart lib/features/auth/ui/view/account/widgets/account_user_tile.dart lib/features/common/ui/settings_page.dart lib/features/policy/ui/widgets/policy_detail_controls.dart test/auth/account_page_test.dart test/core/navigation/workspace_navigation_widgets_test.dart test/tenant/tenant_selection_page_test.dart`
- `flutter test test/auth/account_page_test.dart test/core/navigation/workspace_navigation_widgets_test.dart test/tenant/tenant_selection_page_test.dart`

Follow-up validation after the missed branch-selection surface was fixed:
- `flutter analyze lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart test/branch/branch_selection_page_test.dart`
- `flutter test test/branch/branch_selection_page_test.dart`

Coverage now includes:
- account utility-hub rendering + settings navigation
- tenant-selection app-bar utility cleanup
- tenant portal shell account action presence
- wide tenant rail account action presence
- branch shell account action presence

Manual QA checklist recorded for human pass:
1. Tenant selection
   - confirm `Settings` and `Log out` icons are gone
   - confirm `Inbox` and `Account` remain reachable
   - confirm tapping `Account` opens the account utility page
2. Tenant portal
   - confirm top-right chrome reads as notifications + connectivity + account
   - confirm no standalone settings action remains
3. Wide tenant rail
   - confirm the top-right overlay includes account without crowding the tenant chrome
   - confirm account opens without breaking rail selection state
4. Branch shell
   - confirm account is visible in the branch app bar beside the existing shell indicators
   - confirm page-specific actions still remain usable
5. Role sweep
   - confirm the same account entry is reachable for owner/admin and staff/cashier paths

Note:
- the manual QA checklist is now documented and the focused automated coverage passed
- I did not perform a literal human click-through on every listed surface

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Inventory locked: tenant selection still has inbox/settings/logout icons, portal and rail differ by role/layer, branch shell has no account entry, and Account/Settings routes exist but are too thin to absorb shell utility controls without follow-through |
| 1 | Complete | Locked shell utility IA: account stays a universal shell app-bar entry for all roles/workspaces, shell keeps only notifications/connectivity/account, settings/logout move under Account, and account opens directly to the account page rather than an intermediate menu |
| 2 | Complete | Account is now a viable utility hub: sectioned profile/access/settings/session layout, explicit settings route entry, logout moved under session, membership-based access summary added, and account/settings utility pages no longer expose the inherited no-op Edit action |
| 3 | Complete | Standalone settings/logout were removed from tenant shell surfaces, one shared account shell action now exists across tenant selection, portal, wide rail, and branch shell, and focused widget coverage now locks the normalized utility chrome |
| 4 | Complete | Focused widget coverage now spans account, tenant selection, tenant portal shell, wide rail, and branch shell; analyze/test passed on the touched surface set; manual QA checklist is documented for human follow-through |
