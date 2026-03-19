# Sale Fulfillment + Claims Tabs

Status: Complete

## Why

The current fulfillment screen is carrying two different operator jobs:

- kitchen/service progress tracking for paid direct-checkout orders
- external payment claim handling for outage/manual-proof flows

Those should not share one mixed list.

## Locked direction

Keep the current sale shell tab as `Fulfillment`, but split the page into two top tabs:

1. `Kitchen`
2. `External Claims`

## Tab meaning

### Kitchen

Purpose:
- fulfillment tracking for paid work

Query:
- `GET /v0/orders?view=FULFILLMENT_ACTIVE`

Primary chips:
- `Pending`
- `Preparing`
- `Ready`
- `Delivered`

Primary action:
- update fulfillment status

### External Claims

Purpose:
- manual external-payment claim handling
- local claim recovery
- manager review handoff

Query:
- current contract fallback: `GET /v0/orders?status=OPEN`
- plus local outage-claim projection already stored in frontend

Primary action:
- open detail and continue claim flow

Primary status meaning:
- `Claim Recorded`
- `Claim Pending`
- `Claim Rejected`

## Scope

- do not reintroduce full pay-later UI
- do not mix `Pending payment` copy back into fulfillment
- keep kitchen queue paid-order focused
- keep manual-claim rows out of the kitchen queue

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 IA lock | Completed | Two top tabs only: `Kitchen` and `External Claims`. |
| 1 Model helpers | Completed | Claim-queue detection + status helpers added to the order projection. |
| 2 Fulfillment UI split | Completed | Top tabs added for `Kitchen` and `External Claims`. |
| 3 Shell refresh alignment | Completed | Sale shell refresh now respects the selected fulfillment tab. |
| 4 Validation | Completed | `flutter analyze` and focused sale tests passed. |
