# Tenant Workspace App Bar Actions

Goal: standardize tenant-workspace utility chrome with a shared `TenantWorkspaceAppBarActions` widget used by every tenant page that owns an `AppBar`.

## Problem

Tenant utility actions are currently owned inconsistently:

- some tenant surfaces render their own utility row
- some depended on the wide shell overlay
- after removing the wide overlay to fix duplication, some tenant pages lost notification/sync visibility entirely

This creates two classes of bugs:

1. duplicated utility controls
2. missing utility controls

## Locked Direction

- Do **not** restore the old wide-shell overlay pattern.
- Tenant app-bar utility ownership should be explicit and local.
- Introduce a shared `TenantWorkspaceAppBarActions` widget.
- Every tenant page with an `AppBar` should use that shared widget.
- Branch workspace continues to use branch-specific app-bar actions via `BranchWorkspaceScaffold`.

## Important Boundary

This refactor only solves **tenant chrome ownership**.

It does **not** complete the notification scope migration.

Current notification action is still branch-gated, so tenant-level notification behavior remains dependent on the future tenant-scoped notification contract cutover.

## Scope

Primary targets:

- `lib/core/widgets/navigation/portal_shell.dart`
- `lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart`
- `lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart`
- `lib/features/branchV2/ui/view/branch_detail/branch_management_page.dart`
- `lib/features/branch_subscription/ui/view/branch_subscription_page.dart`

Potential follow-on audit targets:

- tenant feature pages under branch/menu/inventory/staff that own their own `AppBar`

## Non-Goals

- no tenant-level notification contract migration in this slice
- no branch-shell action redesign in this slice
- no return to global shell overlays

---

## Phase 0 — Inventory

- [x] list tenant pages with `AppBar`
- [x] classify current utility ownership:
  - shared/local
  - overlay-dependent
  - none
- [x] lock initial target set

Output:
- inventory table of tenant pages requiring adoption

### Phase 0 Findings

| Surface | File | Current utility ownership | Notes |
|---|---|---|---|
| Tenant portal | `lib/core/widgets/navigation/portal_shell.dart` | Local custom row | Already renders notification + sync + account directly in the app bar |
| Tenant selection | `lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart` | Local partial row | Renders invitation inbox + account, not the operational tenant utility strip |
| Branch selection in tenant context | `lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart` | None/partial | Now only renders account after logout cleanup |
| Branch management | `lib/features/branchV2/ui/view/branch_detail/branch_management_page.dart` | None | Plain app bar with back only |
| Branch subscription | `lib/features/branch_subscription/ui/view/branch_subscription_page.dart` | None | Plain app bar with title only |

### Shell-Level Finding

- `lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart` no longer supplies a wide tenant utility overlay.
- That was correct for duplicate-icon cleanup, but it means tenant pages without their own utility row now show nothing.

### Notification Boundary Confirmed

- `lib/features/notification/ui/components/operational_notification_inbox_action.dart` is still branch-gated.
- Even after tenant app-bar ownership is standardized, true tenant notification behavior still requires the later tenant-scope notification contract cutover.

### Locked Initial Adoption Set

- `lib/core/widgets/navigation/portal_shell.dart`
- `lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart`
- `lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart`
- `lib/features/branchV2/ui/view/branch_detail/branch_management_page.dart`
- `lib/features/branch_subscription/ui/view/branch_subscription_page.dart`

### Deferred Audit Set

- tenant feature shells/pages under:
  - `lib/features/menu`
  - `lib/features/inventory`
  - `lib/features/staff`
- These are follow-on because many already own feature-local app bars and may need the same shared actions later, but they are not the immediate regression path from the recent shell/account changes.

---

## Phase 1 — Shared Widget

- [x] create `TenantWorkspaceAppBarActions`
- [x] define ordering and compactness rules
- [x] make `PortalShell` consume the shared widget instead of a custom row

Output:
- shared tenant utility widget in place

### Phase 1 Result

- Added `lib/core/widgets/navigation/tenant_workspace_app_bar_actions.dart`
- Locked tenant action ordering to:
  - operational notifications
  - sync/connectivity
  - account
- Locked compact presentation for tenant app-bar usage:
  - `OperationalNotificationInboxAction(compact: true)`
  - `GlobalSyncStatusIndicator(compact: true)`
- `PortalShell` now consumes the shared widget instead of hand-assembling its own tenant utility row

Note:
- `tenant_selection_page.dart` still keeps its invitation inbox button as an additional page-specific action ahead of the shared tenant strip
- that is intentional and does not reintroduce the old shell overlay problem

---

## Phase 2 — Adoption Sweep

- [x] apply shared widget to tenant pages that own their own `AppBar`
- [x] remove page-local duplicated utility controls
- [x] keep account access consistent across tenant surfaces

Output:
- tenant pages use one consistent utility strip

### Phase 2 Result

Adopted the shared tenant utility widget in:

- `lib/core/widgets/navigation/portal_shell.dart`
- `lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart`
- `lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart`
- `lib/features/branchV2/ui/view/branch_detail/branch_management_page.dart`
- `lib/features/branch_subscription/ui/view/branch_subscription_page.dart`

Outcome:

- tenant pages now own utility chrome locally through one shared widget
- no return to shell overlays
- account access remains consistent across the adopted tenant surfaces

---

## Phase 3 — Regression Coverage

- [x] add/update widget tests for:
  - no duplicate utility icons
  - tenant pages still show utility controls
  - portal shell uses the shared widget
- [x] verify branch workspace remains unchanged

Output:
- focused regression coverage around tenant app-bar actions

### Phase 3 Result

Updated coverage:

- `test/tenant/tenant_selection_page_test.dart`
- `test/branch/branch_selection_page_test.dart`
- `test/core/navigation/workspace_navigation_widgets_test.dart`

Added coverage:

- `test/branch/branch_subscription_page_test.dart`

Covered behaviors:

- tenant selection uses the shared tenant action strip plus invitation inbox
- branch selection uses the shared tenant action strip
- portal shell uses the shared tenant action strip without duplicate utility icons
- branch workspace wide/mobile expectations in `workspace_navigation_widgets_test.dart` remain unchanged

---

## Phase 4 — Validation

- [x] `flutter analyze`
- [x] targeted `flutter test`
- [x] manual QA checklist:
  - tenant portal
  - tenant selection
  - branch selection in tenant context
  - branch management
  - branch subscription

Output:
- validated tenant app-bar ownership cleanup

### Phase 4 Result

Validation run:

- `flutter analyze lib/core/widgets/navigation/tenant_workspace_app_bar_actions.dart lib/core/widgets/navigation/portal_shell.dart lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart lib/features/branchV2/ui/view/branch_selection/branch_selection_page.dart lib/features/branchV2/ui/view/branch_detail/branch_management_page.dart lib/features/branch_subscription/ui/view/branch_subscription_page.dart test/tenant/tenant_selection_page_test.dart test/branch/branch_selection_page_test.dart test/branch/branch_subscription_page_test.dart test/core/navigation/workspace_navigation_widgets_test.dart`
- `flutter test test/tenant/tenant_selection_page_test.dart test/branch/branch_selection_page_test.dart test/branch/branch_subscription_page_test.dart test/core/navigation/workspace_navigation_widgets_test.dart`

Manual QA checklist recorded for:

- tenant portal
- tenant selection
- branch selection in tenant context
- branch management
- branch subscription

Boundary:

- this slice does not complete tenant-scoped notification behavior
- the current notification button remains branch-gated until the notification contract cutover lands

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Inventory locked; immediate tenant adoption set identified |
| 1 | Completed | Shared tenant app-bar actions widget created and adopted by portal shell |
| 2 | Completed | Immediate tenant page adoption sweep landed |
| 3 | Completed | Regression coverage updated for tenant action ownership |
| 4 | Completed | Analyze/tests passed; manual QA checklist recorded |
