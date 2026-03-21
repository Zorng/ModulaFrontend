# `GET /v0/orders` Filter Feedback Packet

Status: Ready to send to backend  
Owner context: Frontend POS / Sale-Order UI

## Why this packet exists

The frontend now has three distinct order-workspace queues:

1. `Fulfillment`
2. `Pay Later`
3. `Manual Claims`

`Fulfillment` already has a good backend view:

- `GET /v0/orders?view=FULFILLMENT_ACTIVE`

The remaining two queues still start from:

- `GET /v0/orders?status=OPEN`

and then split client-side.

That works for small lists, but it is not safe long-term because pagination happens
before frontend filtering.

## Current frontend behavior

### 1. Fulfillment

Backend query:

- `GET /v0/orders?view=FULFILLMENT_ACTIVE`

This is fine.

### 2. Pay Later

Current backend query:

- `GET /v0/orders?status=OPEN`

Current frontend filter:

- keep `sourceMode == STANDARD`
- exclude rows where a manual payment claim already exists

Meaning:

- frontend wants editable unpaid open tickets only

### 3. Manual Claims

Current backend query:

- `GET /v0/orders?status=OPEN`

Current frontend filter:

- keep rows where:
  - `sourceMode == MANUAL_EXTERNAL_PAYMENT_CLAIM`, or
  - `manualPaymentClaimId != null`, or
  - `manualPaymentClaimStatus != null`

Meaning:

- frontend wants payment-proof review/reconciliation rows only

## The problem

Because both `Pay Later` and `Manual Claims` begin from the same paginated
`status=OPEN` list, frontend filtering can:

- hide valid rows that are on later pages
- distort counts
- make one queue appear empty even when matching rows exist deeper in the list

This is a correctness issue, not just a convenience issue.

## Recommended backend uplift

There are two acceptable directions.

### Option A — Add low-level filters

Extend `GET /v0/orders` with:

- `sourceMode=STANDARD|DIRECT_CHECKOUT|MANUAL_EXTERNAL_PAYMENT_CLAIM|ALL`
- `manualPaymentClaimStatus=PENDING|REJECTED|APPROVED|NONE|ANY`

Recommended semantics:

- `sourceMode` filters by authoritative order source mode
- `manualPaymentClaimStatus=NONE`
  - means no claim exists on the order
- `manualPaymentClaimStatus=ANY`
  - means any claim exists regardless of status

Recommended frontend queries after this uplift:

- Pay Later:
  - `GET /v0/orders?status=OPEN&sourceMode=STANDARD&manualPaymentClaimStatus=NONE`
- Manual Claims:
  - `GET /v0/orders?status=OPEN&manualPaymentClaimStatus=ANY`

### Option B — Add a dedicated manual-claim review view

Alternative:

- `GET /v0/orders?view=MANUAL_CLAIM_REVIEW`

Recommended semantics:

- includes open/manual-claim review rows relevant to operator review
- excludes ordinary editable open tickets

Recommended frontend queries after this uplift:

- Pay Later:
  - `GET /v0/orders?status=OPEN&sourceMode=STANDARD`
- Manual Claims:
  - `GET /v0/orders?view=MANUAL_CLAIM_REVIEW`

## Frontend preference

Preferred minimal uplift:

1. `sourceMode`
2. `manualPaymentClaimStatus`

Reason:

- keeps the endpoint model simple
- avoids inventing too many special-case views
- lets frontend compose queue semantics explicitly

## Non-blocking note

The current frontend already ships with client-side partitioning as a temporary
fallback. This packet is about removing that pagination risk, not enabling a
brand-new UI.

## Requested backend follow-up

Please confirm one of:

1. `GET /v0/orders` will add:
   - `sourceMode`
   - `manualPaymentClaimStatus`
2. or backend prefers a dedicated:
   - `view=MANUAL_CLAIM_REVIEW`

If option 1 is accepted, frontend can remove the lossy client partitioning for:

- `Pay Later`
- `Manual Claims`
