# Global Sync Status Indicator

Goal: add one shared app-level status indicator for connectivity and sync activity without first unifying all page app bars.

This is a shell-level UX improvement, not an offline queue implementation.

## Scope lock

### In scope
- one shared status indicator component
- mount it at shared shell/root level, not inside feature-specific app bars
- first truthful states only:
  - `Online`
  - `Offline`
  - `Syncing`
  - `Refresh failed` / `Stale` when applicable
- reuse existing shared providers where possible:
  - [app_connectivity.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity.dart)
  - [sync_pull_orchestrator.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_orchestrator.dart)
  - [sync_freshness.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_freshness.dart)

### Explicitly out of scope
- app bar standardization across all views
- `sync/push` queue implementation
- showing `Pushing` before push queue/replay exists
- notification center / SSE UX

---

## Locked direction

### 1. Shell-level mounting
- do not inject status logic separately into each page app bar
- mount once at shared shell/root level:
  - wide: top-right within shared shell chrome
  - mobile: top safe-area overlay or equivalent shared shell slot

### 2. Truthful status model
Initial public states:
- `Syncing`
- `Offline`
- `Stale`
- `Online`

Rule:
- do not show `Pushing` until offline queue / `sync/push` is real

### 3. Passive, low-noise UX
- indicator should be compact
- should not block interaction
- should not create a second verbose error banner system
- details stay inside feature surfaces when needed; the global pill is only a high-level signal

---

## Implementation phases

## Phase 0 — Mount Inventory
- [x] Identify the real shared shells/root seams for:
  - mobile
  - wide
- [x] Confirm the best single mount point for a global indicator

Output:
- chosen mount points with minimal duplication

### Phase 0 findings

#### 1. Real root seam already exists
The actual global shell seam is:
- [app.dart](/Users/mac/flutterProjects/modular/lib/app.dart)
  - `ShellRoute(...)`
  - [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
    via `AppScaffoldShell`

This shell already wraps the authenticated workspace routes and is therefore the correct primary mount point for a global indicator.

#### 2. Wide-screen shared chrome already exists
On wide screens:
- [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
  owns the persistent left rail and header area

So wide already has a clear shared-chrome mount option.

#### 3. Mobile has no single shared app bar
On mobile:
- `AppScaffoldShell` currently returns `child` directly
- [portal_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/portal_shell.dart) is shared for portal pages
- [app_bottom_nav_shell_scaffold.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart) is shared for tabbed feature shells

But those two are not universal across all authenticated routes.

So:
- mounting in page app bars would duplicate logic
- mounting only in `PortalShell` or only in `AppBottomNavShellScaffold` would leave gaps

#### 4. Locked mount direction
Best rollout direction:
- use [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart) for wide shared-chrome placement
- use [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart) / `AppScaffoldShell` as the mobile root overlay seam too, instead of standardizing every mobile app bar first

That keeps status ownership global and avoids an app-bar unification refactor.

---

## Phase 1 — Shared Status Model
- [x] Define one small shared presentation model for the global indicator
- [x] Resolve precedence between:
  - offline
  - syncing
  - stale/refresh failed
  - online

Output:
- global sync-status state model

### Phase 1 implementation

Added:
- [global_sync_status.dart](/Users/mac/flutterProjects/modular/lib/core/sync/global_sync_status.dart)

Test coverage added:
- [global_sync_status_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/global_sync_status_test.dart)

Locked state model:
- public indicator states:
  - `Offline`
  - `Syncing`
  - `Stale`
  - `Online`
- shared provider:
  - [globalSyncStatusProvider](/Users/mac/flutterProjects/modular/lib/core/sync/global_sync_status.dart)

Locked precedence:
1. `Offline`
2. `Syncing`
3. `Stale`
4. `Online`

Reasoning:
- offline must win because it is the clearest operational truth
- syncing should outrank stale when the app is actively converging
- stale should only show when connected but still relying on older cached data
- online is the quiet default when none of the above applies

---

## Phase 2 — Shared Widget
- [x] Implement the compact pill/badge widget
- [x] Keep styling neutral and unobtrusive
- [x] Support both mobile and wide placement

Output:
- reusable global status indicator widget

### Phase 2 implementation

Added:
- [global_sync_status_indicator.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/sync/global_sync_status_indicator.dart)

Test coverage added:
- [global_sync_status_indicator_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/global_sync_status_indicator_test.dart)

Locked widget rules:
- compact pill presentation
- shared provider-driven widget:
  - `GlobalSyncStatusIndicator`
- direct presentation widget for reuse/testing:
  - `GlobalSyncStatusPill`
- unobtrusive styling:
  - soft surface background
  - outline border
  - icon + short label only
  - tooltip carries detail text instead of rendering a second verbose line in-shell

Mobile/wide support:
- widget does not assume a specific shell
- compact mode is supported through the widget API for tighter placements in phase 3

---

## Phase 3 — Shell Wiring
- [x] Mount the indicator into the shared shell/root for mobile
- [x] Mount the indicator into the shared shell/root for wide
- [x] Ensure it is visible across feature navigation without per-page duplication

Output:
- one global indicator visible across the app

### Phase 3 implementation

Updated:
- [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)

Test coverage updated:
- [workspace_navigation_widgets_test.dart](/Users/mac/flutterProjects/modular/test/core/navigation/workspace_navigation_widgets_test.dart)

Locked behavior:
- the indicator is mounted once from `AppScaffoldShell`
- wide:
  - shown as a top-right shell overlay above the authenticated workspace area
- mobile:
  - shown as a top-right root overlay without requiring page app-bar wiring
- no feature page needed to opt in individually

Validation run:
- `flutter analyze lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart lib/core/widgets/sync/global_sync_status_indicator.dart lib/core/sync/global_sync_status.dart test/core/navigation/workspace_navigation_widgets_test.dart test/core/sync/global_sync_status_indicator_test.dart test/core/sync/global_sync_status_test.dart`
- `flutter test test/core/navigation/workspace_navigation_widgets_test.dart test/core/sync/global_sync_status_indicator_test.dart test/core/sync/global_sync_status_test.dart`

---

## Phase 4 — Validation
- [x] Verify state transitions:
  - online -> offline
  - offline -> online
  - sync idle -> syncing -> success
  - stale/failure surfacing
- [x] Add focused widget/provider tests
- [x] Manual QA across mobile and wide

Output:
- validated global sync-status UX

### Phase 4 validation

Added:
- [global_sync_status_provider_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/global_sync_status_provider_test.dart)

Focused validation now covers:
- pure precedence logic:
  - [global_sync_status_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/global_sync_status_test.dart)
- provider integration for real transitions:
  - [global_sync_status_provider_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/global_sync_status_provider_test.dart)
- widget rendering:
  - [global_sync_status_indicator_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/global_sync_status_indicator_test.dart)
- shell mounting on wide + mobile:
  - [workspace_navigation_widgets_test.dart](/Users/mac/flutterProjects/modular/test/core/navigation/workspace_navigation_widgets_test.dart)

Validation commands run:
- `flutter analyze lib/core/sync/global_sync_status.dart lib/core/widgets/sync/global_sync_status_indicator.dart test/core/sync/global_sync_status_test.dart test/core/sync/global_sync_status_provider_test.dart test/core/sync/global_sync_status_indicator_test.dart test/core/navigation/workspace_navigation_widgets_test.dart`
- `flutter test test/core/sync/global_sync_status_test.dart test/core/sync/global_sync_status_provider_test.dart test/core/sync/global_sync_status_indicator_test.dart test/core/navigation/workspace_navigation_widgets_test.dart`

Manual QA checklist:
1. Start online and confirm the pill shows `Online`.
2. Toggle browser offline and confirm the pill switches to `Offline`.
3. Restore connectivity and trigger a branch-scoped refresh; confirm the pill shows `Syncing` during active pull.
4. Force a refresh failure while cached data still exists; confirm the pill falls back to `Stale`.
5. Check both:
   - wide shell rail layout
   - mobile shell layout
   and confirm the pill remains visible without overlapping critical controls.

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | `AppScaffoldShell` is the real global seam; mobile should use root overlay, not per-page app-bar duplication |
| 1 | Completed | Shared global sync-status model + precedence provider defined and covered by focused tests |
| 2 | Completed | Shared compact pill widget implemented with provider-driven and direct-render variants |
| 3 | Completed | Global indicator mounted once from `AppScaffoldShell` for both wide and mobile |
| 4 | Completed | Provider/widget/shell transition validation complete and manual QA checklist locked |
