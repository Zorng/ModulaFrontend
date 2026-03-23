# Shell Status And Sale Layout Rework

Goal: lock the redesign problem statement before solution work begins, so notification, sync, connectivity, and sale-layout discussions do not drift into separate ad hoc fixes.

## Why This Exists

The app chrome was originally good enough for navigation-first workflows.

That is no longer enough.

The frontend now has cross-cutting operational state that must be visible and understandable while users work:
- connectivity (`offline` / `online`)
- sync state (`syncing`, `stale`, queue pending, replay issues)
- notifications that require action

At the same time, the sale workspace still has a breakpoint/layout conflict around the middle tier.

These are now related shell problems, not isolated widget problems.

## Accepted Direction So Far

The final visual solution is still open, but these scope decisions are now locked.

### 1) Operational signal ownership

- `Notifications` should remain visible at shell level across the app
- `Connectivity` should remain visible at shell level across the app
- `Devices / peripherals` should remain branch-scoped, not global

So the shell model we are designing toward is:
- global shell signals:
  - notifications
  - connectivity
- branch workspace operational signals:
  - devices / peripherals

### 2) Notification scope model is tenant-level

Backend confirmed that current notification implementation is strictly branch-context scoped today, but the accepted target direction is now **tenant-level notification context**, not the earlier hybrid model.

Locked target model:
- inbox/unread/stream/read state should move to:
  - `(tenantId, accountId)`
- branch remains:
  - origin metadata
  - filter dimension
  - deep-link context for resolution

Authorization boundary remains strict:
- tenant-level does **not** mean unrestricted cross-branch visibility
- an account only sees notifications for which it has an authorized recipient row
- recipient resolution still follows business rules at emit time

Practical frontend implication:
- the shell bell can stay globally visible everywhere in tenant scope
- shell-level notification UX no longer needs to pretend it is branch-local
- branch context is entered only when resolving a branch-specific notification action
- notification payloads should include `branchId` and `branchName` so frontend does not need extra branch lookups

### 3) Sale medium-breakpoint problem remains part of the same rework

The shell redesign must still account for the `medium` sale-layout conflict.

Removing rail pressure from branch workspace is still part of the design discussion, but the exact branch navigation solution is not locked yet in this note.

## Locked Problem Statement

### 1) Operational status is under-designed in shared app chrome

Current shell surfaces do not yet provide a coherent place for:
- connectivity truth
- sync truth
- notifications/action queue truth

Current symptoms:
- wide shell uses a floating top-right overlay for sync + notification
- mobile shell app bar shows notification but not the same sync/connectivity model
- connectivity is not presented as first-class status
- users do not get one consistent operational mental model across breakpoints

### 2) Sale layout still has a middle-breakpoint conflict

Per [responsive_breakpoints.md](/Users/mac/flutterProjects/modular/docs/responsive_breakpoints.md):
- `small`: width < `640`
- `medium`: `640 <= width < 1024`
- `large`: `>= 1024`

Current issue:
- in the sale UI, the `medium` experience still mixes shell/navigation behavior with feature-internal tab behavior awkwardly
- specifically, we still have rail-style shell behavior pressure while the sale feature also treats cart as an internal tab/workspace
- this creates a confused layout hierarchy in the middle breakpoint

This is not just styling debt. It is an information architecture problem.

## Locked Goals

### Goal A — Establish one operational status model across the app shell

The redesign must make these states first-class and easy to scan:
- connectivity
- sync state
- notification attention state

Required outcome:
- users can immediately tell whether the app is healthy, offline, syncing, stale, or awaiting action
- this must work consistently across `small`, `medium`, and `large`

### Goal B — Clarify shell-vs-feature hierarchy on the sale workspace

The redesign must remove the current middle-breakpoint ambiguity between:
- shell navigation structure
- sale-internal navigation structure

Required outcome:
- the sale workspace has one clear navigation hierarchy at each breakpoint
- `medium` must no longer feel like two navigation systems competing in the same viewport

### Goal C — Avoid page-by-page patching

This rework must be solved at the shared shell/layout level first.

We should not:
- keep adding isolated badges/buttons/overlays
- fix notification UI alone
- fix sale layout alone
- fix one breakpoint and leave the others to drift

## Non-Goals

This note does **not** choose the final solution yet.

Not locked yet:
- exact visual design
- final placement of the operational status zone
- exact branch-workspace navigation mechanism (for example drawer vs another shell pattern)
- whether the sale medium breakpoint keeps tabs, collapses tabs, or changes shell behavior
- whether notification inbox itself needs a second-pass redesign

## Constraints

- Must respect [responsive_breakpoints.md](/Users/mac/flutterProjects/modular/docs/responsive_breakpoints.md)
- Must preserve `go_router` navigation model
- Must keep source business pages authoritative; notifications must not become a parallel truth layer
- Must respect the accepted tenant-level notification model:
  - notification inbox/unread/stream/read state is tenant/account scoped
  - branch remains origin metadata and action context, not primary inbox scope
- Must work with the existing shell surfaces:
  - [app_wide_navigation_rail_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_wide_navigation_rail_shell.dart)
  - [app_bottom_nav_shell_scaffold.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_bottom_nav_shell_scaffold.dart)
  - [portal_shell.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/portal_shell.dart)

## Success Criteria

We should consider this rework successful when:
- users can identify operational state without opening extra pages
- wide and mobile shells communicate the same status model
- sale `medium` breakpoint has a clearly intentional hierarchy
- notification, sync, and connectivity no longer feel like incidental add-ons

## Next Step

Next prompt should define the shell/navigation solution against this locked problem statement and the accepted tenant-level notification scope.
