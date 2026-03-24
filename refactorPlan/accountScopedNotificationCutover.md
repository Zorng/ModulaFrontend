# Account-Scoped Notification Cutover

Goal: move operational notifications from tenant-scoped utility semantics to a true account-scoped shell utility, while preserving strict recipient-based authorization and clear tenant/branch origin context.

## Why This Exists

The current notification situation is blurry because the product and the contract are pointing at different levels.

What frontend wants:
- one bell that behaves like a shell/account utility
- visible coherently across account, tenant, and branch surfaces

What current implementation provides:
- tenant-scoped inbox/count/stream semantics
- branch-origin metadata
- branch-scoped business-page resolution

That mismatch is what created the recent UX and routing confusion.

## Problem Context

### 1) Current tenant-scoped contract is coherent by itself

Current contract:
- inbox scope = `(tenantId, accountId)`
- branch remains metadata
- authorization remains recipient-row based

This is valid when notifications are treated as a tenant utility.

### 2) Current shell direction is pushing toward account utility behavior

The frontend shell redesign has already been moving toward:
- notifications as shared shell chrome
- account as a universal utility entry
- less dependence on individual workspace-specific chrome

That makes notifications feel like they belong at the account level, not only inside one selected tenant.

### 3) The resulting mismatch creates recurring UX bugs

Symptoms we have already seen:
- notification bell shown on surfaces that do not have a clean tenant-utility boundary
- routing ambiguity between tenant utility pages and branch workflow pages
- uncertainty about whether notifications should appear before tenant selection
- confusion about whether `/notifications` is:
  - account-global
  - tenant utility
  - branch workflow support

The issue is not only implementation quality.
The underlying scope model is mixed.

## Backend Alignment

Backend has now agreed with the long-term direction:

- account scope is cleaner if the bell is meant to be a true shell/account utility
- scope should become `(accountId)`
- authorization must remain recipient-row based
- origin metadata must include:
  - `tenantId`
  - `tenantName`
  - `branchId`
  - `branchName`

Backend account-scope cutover is now complete:
- inbox/count/detail/read/read-all/stream are account-scoped
- selected tenant is not required
- selected branch is not required
- payloads include:
  - `tenantId`
  - `tenantName`
  - `branchId`
  - `branchName`

## Accepted Long-Term Target

### Notification scope

- inbox/count/detail/read/read-all/stream become account-scoped
- aggregation scope = `(accountId)`

### Authorization rule

- account scope does **not** broaden access
- an account only sees notification rows for which it has a resolved recipient row
- recipient resolution remains business-rule driven at emit time

### Origin metadata

Every notification row should carry:
- `tenantId`
- `tenantName`
- `branchId`
- `branchName`

### Filtering

Inbox should support optional narrowing filters:
- `tenantId`
- `branchId`
- `unreadOnly`
- `type`
- `limit`
- `offset`

## Current Frontend Status

Frontend account-scope cutover is now in progress/completed across the core path:
- unread badge is account-scoped
- inbox is account-scoped
- route access before tenant selection is allowed for `/notifications`
- realtime stream binding no longer requires tenant selection
- tenant and branch are rendered as notification origin metadata

The main remaining product/runtime boundary is no longer scope itself.
It is notification resolution handoff:
- notifications still route into existing business pages
- explicit tenant/branch handoff before branch-scoped workflows is still a separate follow-up

## Scope

Likely areas affected by the eventual cutover:
- `integration/operational-notification-v0.md`
- `lib/features/notification/data/*`
- `lib/features/notification/ui/*`
- `lib/core/hydration/*`
- `lib/core/widgets/navigation/*`
- notification route ownership and deep-link handoff logic

## Non-Goals

This tracker does not cover:
- invitation inbox
- device/peripheral status
- sale layout redesign
- unrelated tenant/account shell polish

## Phase Plan

## Phase 0 — Lock Assessment And Interim Rule
- [x] record the current mismatch between tenant-scoped contract and account-utility shell placement
- [x] record backend agreement on account-scoped long-term direction
- [x] lock interim frontend rule while tenant-scoped backend remained live

Output:
- one stable reference for “what is current” vs “what is target”

## Phase 1 — Backend Contract Draft Review
- [x] review backend’s account-scoped contract draft
- [x] verify required payload metadata:
  - `tenantId`
  - `tenantName`
  - `branchId`
  - `branchName`
- [x] verify filter semantics
- [x] verify stream lifecycle expectations

Output:
- accepted account-scoped contract assumptions

## Phase 2 — Interim Frontend Cleanup
- [x] remove or limit notification affordances on surfaces that should not imply account-global behavior yet
- [x] stop relying on tenant-scoped notification semantics in pre-tenant/account-global UI
- [x] add regression coverage for the interim rule

Output:
- cleaner temporary UX while backend cutover is pending

## Phase 3 — Frontend Contract Cutover
- [x] update API/repository/controllers to account scope
- [x] add `tenantName` support end-to-end
- [x] update unread badge + inbox + read actions
- [x] update runtime stream binding to account scope

Output:
- account-scoped notification reads and realtime on frontend

## Phase 4 — Route And Resolution Handoff
- [ ] define how notification actions move into tenant/branch business pages
- [ ] avoid silent context jumps where possible
- [x] make tenant/branch origin clear in inbox rows and action flow

Output:
- stable resolution flow from account-level inbox into business pages

## Phase 5 — Validation
- [x] `flutter analyze`
- [x] targeted `flutter test`
- [ ] manual QA across:
  - account/global surfaces
  - tenant surfaces
  - branch workflow surfaces
  - notification tap actions

Output:
- validated account-scoped notification cutover

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Scope mismatch and interim rule were recorded before the backend cutover |
| 1 | Complete | Backend contract reviewed and locked |
| 2 | Complete | Interim cleanup landed while the contract was still changing |
| 3 | Complete | Frontend now reads, badges, routes, and streams notifications at account scope |
| 4 | In progress | Explicit tenant/branch handoff from notifications into business workflows is still open |
| 5 | In progress | Analyze + targeted tests are green; manual QA is still pending |
