# Sale Offline Cash Push Replay

Status: Implemented

## Why

Backend now supports one sale replay lane through `POST /v0/sync/push`:

- `operationType = "checkout.cash.finalize"`

This should replace the current dead-end local offline cash capture path.

## Scope lock

### In scope
- offline pay-first cash checkout enqueue
- replay through the existing push queue
- local outage-order projection for queued cash checkout
- local outage cleanup after replay success/duplicate
- UI copy updates so offline cash no longer promises manual settlement

### Out of scope
- KHQR replay
- pay-later replay
- general order mutation replay
- manual-claim replay

## Locked backend assumptions

- replay payload must include an immutable priced checkout snapshot
- replay payload must include client-generated `orderId`
- replay payload must include client-generated `saleId`
- success/duplicate should be treated as done
- payload conflict is permanent failure

## Phases

| Phase | Status | Notes |
|---|---|---|
| 0 Scope + contract lock | Completed | Backend update overrides the older local push-sync doc for this sale lane. |
| 1 Queue operation foundation | Completed | Added `checkout.cash.finalize` to the shared offline queue operation set. |
| 2 Cart enqueue path | Completed | Offline cash cart flow now stores the outage projection and enqueues a replay-safe `checkout.cash.finalize` payload with priced line snapshots plus client-generated order/sale ids. |
| 3 Local outage convergence | Completed | Orders now reconcile queued cash outage rows against queue state, hide applied/duplicate rows, and surface replay failures through the existing outage projection. |
| 4 UI cleanup | Completed | Cash capture copy now says queued/replayed, kitchen can see queued cash rows, and order detail only keeps the old manual-settlement action for legacy pre-queue records. |
| 5 Validation | In progress | Focused analyze/tests passed; manual reconnect QA for applied/duplicate/conflict outcomes is still pending. |
