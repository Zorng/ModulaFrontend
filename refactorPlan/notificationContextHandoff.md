# Notification Context Handoff

Goal: make notification actions open the correct business UI without relying on implicit delayed redirects, while preserving authorization boundaries and clear tenant/branch context.

## Why This Exists

Operational notifications are now account-scoped.

That means:
- the inbox can be opened from account/global shell surfaces
- a notification may belong to a different tenant or branch than the user is currently viewing
- clicking a notification can no longer assume the current workspace context already matches the notification origin

The current result is blurry and bug-prone:
- click appears to do nothing
- later, after entering a tenant/branch, the app suddenly jumps to a page
- the transition is implicit rather than user-understandable

This tracker exists to separate that problem from notification scope, inbox UI, and shell placement.

## Locked Principles

### 1) Notification inbox is a utility surface, not the final workflow surface

- bell opens a modal/bottom sheet inbox
- clicking a notification should navigate into an existing business page
- notifications do not become their own duplicate workflow UI

### 2) Existing business pages remain the source of truth

- do not trust notification payload as current state
- pass only the minimum route identifier needed
- destination page must refetch current state from backend
- backend authorization remains authoritative

### 3) Do not silently defer a context jump

Bad pattern:
- click notification
- nothing visible happens
- later, after tenant/branch entry, the app unexpectedly jumps

Target pattern:
- if context already matches, navigate directly
- if context differs, show an explicit handoff step

### 4) Reuse the correct existing detail pages

For current closed-session notifications:
- reuse the existing closed-session detail route/page
- do not route into the live `Z Report` branch workspace page

Current intended closed-session target:
- `AppRoute.cashHistoryDetail`
- backed by `CashSessionHistoryDetailPage`
- reads authoritative detail via `fetchZReportDetail(sessionId: ...)`

### 5) Account scope does not broaden authorization

- notification visibility is still recipient-row based
- destination access must still pass normal tenant/branch/business authorization
- handoff UX must not create a bypass around normal route guards

## Problem Scope

Affected areas likely include:
- `lib/features/notification/ui/viewmodels/operational_notification_navigation.dart`
- notification click behavior from the modal inbox
- tenant selection / branch selection continuation behavior
- route guards in `lib/app.dart`
- closed-session detail navigation
- future void-approval action routing

## Current Known Symptom

Observed bug pattern:
- admin opens account-scoped inbox
- sees closed-session notification
- clicks `View session`
- nothing visible happens
- later enters tenant and branch
- app immediately jumps to a session UI

This strongly suggests the current path is being converted into delayed branch-scoped continuation behavior instead of explicit handoff.

## Target UX Model

### Case A — Current context already matches notification origin

- navigate directly to the business page

Examples:
- already inside the correct tenant/branch and click `View session`
- already in the right branch and click `Open carts`

### Case B — Current context differs from notification origin

- show an explicit handoff prompt

Prompt should explain:
- destination tenant
- destination branch
- intended page/action

Example copy:
- `Switch to Tenant A / Main Branch to view this closed session?`

### Case C — User lacks current access

- do not navigate
- show a clear message that the notification can no longer be opened

Examples:
- membership revoked
- branch access removed
- session/sale no longer visible under current permissions

## Current Route Reuse Decisions

### Closed cash session

Use:
- `AppRoute.cashHistoryDetail`

Why:
- read-only historical detail
- already tied to session history semantics
- already fetches server-authoritative report detail by `sessionId`

Do not use:
- `ZReportPage`

Why not:
- it is a branch workspace page
- it is framed as a current branch/date report surface
- that is the wrong semantic level for account-scoped notification handoff

### Void-related notifications

Current reuse direction:
- existing sale history / carts flows

Future actionable direction:
- route into the existing approval/review workflow UI
- not into a notification-only action page

## Non-Goals

This tracker does not cover:
- notification scope migration
- inbox modal design polish
- tenant/account shell redesign
- backend recipient/auth changes

## Phase Plan

## Phase 0 — Inventory Current Notification Actions
- [x] list current notification types and their existing route targets
- [x] identify which targets are:
  - direct-safe
  - branch-context-dependent
  - tenant-context-dependent
- [x] confirm which current routes already map to correct read-only vs actionable business pages

Output:
- action-routing inventory table

### Phase 0 Output

| Notification type | Current target | Target class | Reuse decision |
|---|---|---|---|
| `CASH_SESSION_CLOSED` | `AppRoute.cashHistoryDetail` when `sessionId` exists, else `AppRoute.cashHistory` | branch-context-dependent | correct read-only reuse; keep historical cash-session detail |
| `VOID_APPROVAL_NEEDED` | `AppRoute.saleViewCarts?state=VOID_PENDING...` | branch-context-dependent | acceptable temporary reuse; explicit handoff still pending |
| `VOID_APPROVED` | `AppRoute.saleViewCarts?state=VOIDED...` | branch-context-dependent | acceptable temporary reuse; explicit handoff still pending |
| `VOID_REJECTED` | `AppRoute.saleViewCarts?state=FINALIZED...` | branch-context-dependent | acceptable temporary reuse; explicit handoff still pending |

Inventory conclusion:
- all current notification actions land in existing business pages
- all current actions are branch-context-dependent once they leave the inbox
- only `CASH_SESSION_CLOSED` is locked for this slice because it already has the correct read-only destination page

## Phase 1 — Lock Context Handoff Rules
- [x] define direct-navigation rule when current context already matches
- [x] define explicit prompt rule when tenant/branch differs
- [x] define failure UX when access is no longer valid
- [x] define whether handoff is confirm-first or auto-switch-with-banner

Output:
- stable UX contract for notification action handoff

### Phase 1 Output

Locked rules:
- if current tenant + branch already match notification origin, navigate directly
- if tenant or branch differ, show an explicit confirm-first prompt before any switch happens
- do not silently queue a `continue=` redirect from notification click
- if access is stale or switch fails, stay in the inbox surface and show a clear failure message

Current confirm-first copy shape:
- title: `Switch workspace?`
- body: `Switch to <tenant> / <branch> to view this closed session?`
- primary action: `Switch and view`

## Phase 2 — Closed Session Flow
- [x] wire `CASH_SESSION_CLOSED` to the existing closed-session detail flow
- [x] add explicit tenant/branch handoff before navigation when needed
- [x] remove implicit delayed-jump behavior
- [x] add regression coverage for:
  - same-context direct open
  - cross-context prompt
  - denied/stale access

Output:
- closed-session notifications behave predictably

### Phase 2 Output

Implemented behavior:
- `View session` still targets the existing `AppRoute.cashHistoryDetail` flow
- same-context click opens the historical session detail directly
- cross-context click shows an explicit workspace-switch prompt
- confirm performs tenant switch, then branch switch, then navigates
- if the account no longer has valid access, the app stays in the inbox and shows a failure message

Files:
- `lib/features/notification/ui/viewmodels/operational_notification_navigation.dart`
- `lib/features/notification/ui/view/operational_notification_inbox/operational_notification_inbox_page.dart`
- `test/notification/operational_notification_inbox_page_test.dart`
- `test/notification/operational_notification_navigation_test.dart`

## Phase 3 — Void Notification Flow
- [x] review current carts/history routing for void notifications
- [x] decide target workflow page for future approve/reject handling
- [x] add the same explicit context handoff rule there

Output:
- void notification actions align with the same handoff model

### Phase 3 Output

Current routing decision:
- keep using the existing carts/history flow for void notifications
- `VOID_APPROVAL_NEEDED` -> `AppRoute.saleViewCarts?state=VOID_PENDING...`
- `VOID_APPROVED` -> `AppRoute.saleViewCarts?state=VOIDED...`
- `VOID_REJECTED` -> `AppRoute.saleViewCarts?state=FINALIZED...`

Why this is the current target:
- it reuses an existing business page instead of inventing a notification-only workflow
- it keeps sale state authoritative
- it is the least risky bridge until a dedicated approve/reject workflow page exists

Implemented behavior:
- same-context `Open carts` navigates directly
- cross-context `Open carts` now uses the same confirm-first tenant/branch handoff
- stale access stays in the inbox and shows failure feedback

Files:
- `lib/features/notification/ui/viewmodels/operational_notification_navigation.dart`
- `lib/features/notification/ui/view/operational_notification_inbox/operational_notification_inbox_page.dart`
- `test/notification/operational_notification_inbox_page_test.dart`
- `test/notification/operational_notification_navigation_test.dart`

## Phase 4 — Shared Handoff Infrastructure
- [ ] extract a small reusable notification-handoff helper if needed
- [ ] ensure continue-path handling does not silently trigger later without user awareness
- [ ] keep route guards authoritative

Output:
- one consistent handoff mechanism across notification types

## Phase 5 — Validation
- [ ] `flutter analyze`
- [ ] targeted `flutter test`
- [ ] manual QA for:
  - account-level inbox
  - tenant-level inbox
  - branch-level inbox
  - same-context navigation
  - cross-context handoff
  - stale/denied notifications

Output:
- validated notification action handoff behavior

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Inventory locked: all current notification actions reuse existing business pages; all are branch-context-dependent after leaving inbox |
| 1 | Completed | Confirm-first handoff contract locked; no more silent deferred jumps from notification click |
| 2 | Completed | Closed-session flow now uses explicit tenant/branch handoff and failure messaging |
| 3 | Completed | Void notifications now use the same explicit handoff model while continuing to target the existing carts/history flow |
| 4 | Not started |  |
| 5 | Not started |  |
