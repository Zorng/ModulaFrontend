# Offline Command Queue

Goal: implement the frontend write-lane for replay-safe offline operations using `POST /v0/sync/push`.

This continues the offline-first foundation after:
- [offlineCachingFoundation.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingFoundation.md)
- [offlineCachingImplementationTracker.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingImplementationTracker.md)

## Scope lock

### In scope
- durable offline command queue storage
- queue records keyed by working context
- `sync/push` transport + result mapping
- enqueue and replay for currently supported operations only
- reconnect/manual flush coordination
- first UX rules for queued vs online-only actions

### Explicitly out of scope
- replay for unsupported operations
- sale finalize offline replay
- KHQR offline behavior
- notification/SSE work
- background polling beyond reconnect/manual flush

---

## Backend constraints (locked)

Currently replay-safe operations:
- `attendance.startWork`
- `attendance.endWork`
- `cashSession.open`
- `cashSession.close`
- `cashSession.movement`

Currently not replay-safe:
- `sale.finalize`
- KHQR/provider-dependent flows

Rule:
- do not queue unsupported writes as if backend can replay them
- unsupported operations must remain online-only

---

## Target architecture

### 1. Queue storage
Persist queue rows with:
- `clientOpId`
- `operationType`
- `tenantId`
- `branchId`
- `accountId`
- `occurredAt`
- `payloadJson`
- `dependsOn`
- `status`
- retry / last-error metadata

### 2. Push coordinator
Shared coordinator that:
- loads pending queue rows for active context
- submits them through `sync/push`
- marks rows:
  - `APPLIED`
  - `DUPLICATE`
  - `FAILED`
- runs `sync/pull` after successful replay batch

### 3. Feature enqueue policy
Replay-safe feature actions should:
- execute online immediately when connectivity is available
- enqueue locally when offline
- surface deterministic queued/offline-safe messaging

### 4. UX rules
- queued replay-safe actions should not pretend they are already server-finalized
- unsupported offline actions must be blocked clearly
- reconnect should attempt replay once, not loop noisily

---

## Implementation phases

## Phase 0 — Replay-safe Inventory
- [x] Map every current replay-safe action to its real frontend entrypoint
- [x] Confirm payload shapes and current client-generated ids
- [x] Confirm which existing actions already carry stable `clientOpId`

Output:
- operation inventory table

### Locked inventory

| Operation type | Frontend entrypoint | Current payload shape | Stable `clientOpId` today | Notes |
|---|---|---|---|---|
| `attendance.startWork` | `AttendanceCheckPage._handleCheckAction()` -> `StaffAttendanceRepository.checkInWithPayload(...)` | `AttendanceCheckInPayload.toJson()` -> `{ occurredAt, location? }` | Yes | UI already generates `attendance-start-...` style ids before calling the repository |
| `attendance.endWork` | `AttendanceCheckPage._handleCheckAction()` -> `StaffAttendanceRepository.checkOutWithPayload(...)` | `AttendanceCheckOutPayload.toJson()` -> `{ occurredAt, location? }` | Yes | UI already generates `attendance-end-...` style ids before calling the repository |
| `cashSession.open` | `CashSessionViewModel.startSession(...)` -> `CashSessionRepository.openSession(...)` | `{ openingFloatUsd, openingFloatKhr, note? }` | No | Queue layer becomes the first place that assigns a replay-stable `clientOpId` |
| `cashSession.close` | `CashSessionViewModel.closeSession(...)` -> `CashSessionRepository.closeSession(...)` | `{ sessionId, countedCashUsd, countedCashKhr, note? }` | No | Queue layer becomes the first place that assigns a replay-stable `clientOpId` |
| `cashSession.movement` | `CashSessionViewModel.recordPaidIn/recordPaidOut/recordAdjustment(...)` | One normalized operation type with payload carrying `sessionId`, `movementType`, amount fields, and `reason` | No | Live API is split across `paidIn`, `paidOut`, `adjustment`; offline queue should normalize them under one replay type |

### Locked exclusions

- `cashSession.forceClose` stays online-only for now
- `sale.finalize` stays online-only until backend replay support exists
- sale outage support now moves to a separate **order-first** workflow plan:
  - [saleOfflineOrderFirst.md](/Users/mac/flutterProjects/modular/refactorPlan/saleOfflineOrderFirst.md)
- KHQR stays strictly online-only
- Queue work in this plan covers replay-safe write storage/transport only, not generic write replay for every feature

---

## Phase 1 — Queue Schema
- [x] Add queue tables to local storage
- [x] Add queue repository/store under `lib/core/sync/`
- [x] Define queue row statuses and transitions

Output:
- durable offline queue storage

---

## Phase 2 — Push Transport + Result Mapping
- [x] Add `sync/push` API transport
- [x] Parse push results (`APPLIED`, `DUPLICATE`, `FAILED`)
- [x] Map deterministic backend failure codes

Output:
- shared push transport layer

---

## Phase 3 — Queue Coordinator
- [x] Implement shared replay coordinator
- [x] Batch pending rows by active context
- [x] Trigger `sync/pull` after successful replay batch

Output:
- end-to-end replay coordinator

---

## Phase 4 — Cash Session Integration
- [x] Queue offline-safe cash-session actions:
  - open
  - close
  - movement
- [x] Keep unsupported actions online-only

Output:
- first replay-safe feature integration

---

## Phase 5 — Attendance Integration
- [x] Queue offline-safe attendance actions:
  - startWork
  - endWork
- [x] Ensure current UI messaging distinguishes queued vs live-applied actions

Output:
- second replay-safe feature integration

---

## Phase 6 — Reconnect / Manual Flush
- [x] Replay queue on reconnect
- [x] Add a safe manual retry/flush entrypoint if needed
- [x] Ensure dedupe/noisy-traffic protections

Output:
- replay lifecycle wiring

---

## Phase 7 — Validation
- [x] Unit test queue storage + status transitions
- [x] Unit test push result mapping
- [x] Widget/provider tests for queued offline-safe actions
- [ ] Manual QA for offline -> reconnect flow

Output:
- validated offline command queue rollout

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Replay-safe inventory locked against current attendance and cash-session entrypoints |
| 1 | Completed | Durable queue table and Drift-backed store landed under `lib/core/sync/` |
| 2 | Completed | `sync/push` transport and defensive result parsing landed |
| 3 | Completed | Replay coordinator landed with context batching and post-push `sync/pull` convergence |
| 4 | Completed | Cash-session open/close/movement now queue when offline; force-close remains online-only |
| 5 | Completed | Attendance check-in/check-out now queue when offline, update local cache optimistically, and surface queued messaging |
| 6 | Completed | Reconnect now replays queued commands first, falls back to `sync/pull` only when nothing is pending, and manual flush has a shared trigger seam with cooldown bypass |
| 7 | In progress | Automated queue/coordinator/widget coverage is in place; manual QA for offline -> reconnect still pending |
