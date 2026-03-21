# Sale + Order UI Tab Refactor

Status: Parked / superseded for current release
Owner context: Frontend POS / Sale-Order UI

Scope note:
- this refactor was explored during the sale/order contract cutover
- the current pay-first sale release no longer ships this mixed 3-tab workspace UI
- current cleanup/active direction is tracked in [salePayFirstScopeCleanup.md](/Users/mac/flutterProjects/modular/refactorPlan/salePayFirstScopeCleanup.md)

## Goal

Split the current overloaded Orders surface into three purpose-specific tabs:

1. `Fulfillment`
2. `Pay Later`
3. `Manual Claims`

This refactor exists because the current mixed list is trying to represent:

- fulfillment work
- unpaid open-ticket management
- manual-claim payment reconciliation

Those are different operational queues with different row actions, chips, and operator questions.

---

## Locked direction

Do not keep all order-related work inside one mixed list with one shared chip model.

Use three tabs, each with:

- its own query strategy
- its own empty state
- its own row actions
- its own chip semantics

Important rule:

- `Fulfillment` is an operational queue
- `Pay Later` is an unpaid/open-ticket workflow
- `Manual Claims` is a payment-proof review/reconciliation queue

They are related, but they are not the same UI problem.

---

## Mental model

### Tab 1 — Fulfillment

Question:

- what needs kitchen/service action now?

Current backend query:

- `GET /v0/orders?view=FULFILLMENT_ACTIVE`

Current backend behavior:

- includes `OPEN` orders still in fulfillment flow
- includes `CHECKED_OUT` `DIRECT_CHECKOUT` orders still in fulfillment flow
- excludes `CANCELLED`
- excludes latest fulfillment status `COMPLETED` / `CANCELLED`

Primary chip:

- `fulfillmentStatus`

Recommended row actions:

- open detail
- update fulfillment status

### Tab 2 — Pay Later

Question:

- which unpaid open tickets can still be edited, settled, or cancelled?

Current backend query:

- `GET /v0/orders?status=OPEN`

Current frontend filter:

- keep `sourceMode == STANDARD`
- exclude rows with `manualPaymentClaimId != null`

Primary chip guidance:

- the tab already explains this is unpaid/open-ticket workflow
- avoid turning this tab into a payment-status explanation board

Recommended row actions:

- add items
- checkout
- cancel

### Tab 3 — Manual Claims

Question:

- which orders need payment-proof review or reconciliation follow-up?

Current backend query:

- `GET /v0/orders?status=OPEN`

Current frontend filter:

- keep rows where:
  - `manualPaymentClaimId != null`, or
  - `sourceMode == MANUAL_EXTERNAL_PAYMENT_CLAIM`

Primary chip:

- claim status, not fulfillment status

Recommended row actions:

- open detail
- approve claim
- reject claim

---

## Important design rule

Do not force one chip model across all three tabs.

### Fulfillment

Main chip:

- `Pending`
- `Preparing`
- `Ready`
- `Completed`

Optional context chip:

- `Direct checkout`
- `Pay later`

Avoid:

- `Pending payment` for already-paid direct-checkout rows

### Pay Later

Main chip:

- optional lightweight lifecycle chip if needed

Avoid:

- claim-review chips as the primary meaning of the row

### Manual Claims

Main chip:

- `Claim pending`
- `Claim rejected`
- `Claim approved`

Avoid:

- using fulfillment lifecycle as the main meaning of this tab

---

## Current-contract tradeoff

For now, `Pay Later` and `Manual Claims` both start from:

- `GET /v0/orders?status=OPEN`

and then partition client-side.

That is acceptable as an interim solution, but it is not the clean long-term state because:

- backend pagination happens before client-side partitioning
- large lists can distort counts and visible rows

So this refactor is allowed to ship on current contract, but the limitation must stay explicit.

---

## Backend follow-ons that would simplify this later

Not blockers for the tab split, but useful follow-ups:

### 1. `sourceMode` filter

Extend `GET /v0/orders` with:

- `sourceMode=STANDARD|DIRECT_CHECKOUT|MANUAL_EXTERNAL_PAYMENT_CLAIM|ALL`

### 2. `manualPaymentClaimStatus` filter

Extend `GET /v0/orders` with:

- `manualPaymentClaimStatus=PENDING|REJECTED|APPROVED|NONE|ANY`

### 3. Dedicated claim-review view

Alternative:

- `GET /v0/orders?view=MANUAL_CLAIM_REVIEW`

---

## Phase plan

### U1 — IA lock

- [x] Lock the three-tab direction
- [x] Lock tab purpose per queue
- [x] Lock chip semantics per queue
- [x] Record current-contract client-filter tradeoff

Output:

- IA and semantics are locked

### U2 — Fulfillment tab cutover

- [x] Move kitchen/counter flow fully to `GET /v0/orders?view=FULFILLMENT_ACTIVE`
- [x] Keep row actions fulfillment-first
- [x] Remove payment-oriented chip misuse from paid direct-checkout rows

Output:

- fulfillment screen is lifecycle-first

### U3 — Pay Later tab cutover

- [x] Create dedicated unpaid open-ticket tab
- [x] Use `GET /v0/orders?status=OPEN` and client-filter editable standard tickets
- [x] Keep pending-claim orders out of the normal pay-later edit queue

Output:

- unpaid open tickets are isolated from fulfillment and claim review

### U4 — Manual Claims tab cutover

- [x] Create dedicated claim-review tab
- [x] Use `GET /v0/orders?status=OPEN` and client-filter claim rows
- [x] Separate claim chips from fulfillment chips

Output:

- payment-proof review becomes its own queue

### U5 — Optional backend filter uplift

- [x] Request `sourceMode` list filtering if pagination/row partitioning becomes too lossy
- [x] Request `manualPaymentClaimStatus` or dedicated claim-review view if needed

Output:

- backend and frontend contract simplify the tab split over time

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| U1 IA lock | Completed | 3-tab split locked: `Fulfillment`, `Pay Later`, `Manual Claims`. |
| U2 Fulfillment tab cutover | Completed | Orders workspace defaults to `Fulfillment`: `FULFILLMENT_ACTIVE`, fulfillment copy, fulfillment status updates. |
| U3 Pay Later tab cutover | Completed | Orders workspace now has a dedicated `Pay Later` queue backed by `status=OPEN` plus client partitioning. |
| U4 Manual Claims tab cutover | Completed | Orders workspace now has a dedicated `Manual Claims` queue with claim-review chips and client partitioning from `status=OPEN`. |
| U5 Optional backend filter uplift | Completed | Backend packet prepared in `refactorPlan/saleOrderFilterFeedbackPacket.md` for `sourceMode` and claim-review filtering. |
