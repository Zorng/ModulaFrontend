# Sale Outage Manual-Claim Restore

Status: In progress  
Owner context: Frontend POS / Sale / Fulfillment / Outage Recovery

## Goal

Restore the supported outage/manual external-payment-claim workflow that
existed before the pay-first defense rollback, while keeping the pay-later /
open-order model disabled.

This restore is intentionally narrow:

- restore outage/manual-claim capture from cart
- restore the `External Claims` reviewer/operator workspace
- restore manual-claim detail/review UI
- keep pay-later / open-ticket creation out of active UI

## Why This Exists

Current `spt5-integration` no longer supports the outage/manual-claim fallback
that was available on `spt5-sale-discount`.

The removal was not an accidental merge loss. It was part of the defense-scope
rollback in commit `1f2f4ae` (`rollback pay later`), which bundled adjacent
order-lane flows into the pay-first cleanup.

## Scope Lock

### Restore

- outage/manual-claim capture from cart
- external-payment-claim queue / `External Claims` workspace
- manual-claim proof / submit / review UI on order detail
- outage recovery handoff back into online review

### Do Not Restore

- pay-later / open-ticket placement
- open-ticket settlement from active UI
- `Allow Pay Later` branch policy editing
- unpaid ticket language as a normal supported checkout path

### Domain Boundary

The outage/manual-claim lane is **not** the same thing as pay-later.

Locked interpretation:

- pay-first remains the normal supported checkout model
- outage/manual-claim capture is an outage exception lane
- external-payment-claim review is a recovery / verification flow
- this restore must not reintroduce generic unpaid ticket behavior
- this restore must not be labeled as offline KHQR gateway settlement

## Current Regression Findings

### What was removed from active UI

1. Cart-side outage/manual-claim capture
- [sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart)
  - removed `_handleOfflineManualClaimCapture(...)`
  - replaced offline QR fallback with:
    - `KHQR checkout is unavailable while offline. Reconnect to continue.`

2. External Claims workspace
- [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
  - active visible tabs no longer include `External Claims`
  - current role tabs are effectively:
    - `Kitchen`
    - `Void Requests` for reviewers

3. Manual-claim order detail UI
- [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart)
  - `_manualClaimUiEnabled = false`
  - manual-claim action surfaces are present in code but intentionally gated off

### What still exists underneath

1. Outage/manual-claim capture logic
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - `captureOfflineManualClaimOrder()`

2. Manual-claim mutation and review state
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  - record / submit / approve / reject manual claim flows still exist
  - `FulfillmentWorkspaceTab.externalClaims` still exists in the enum

3. Outage recovery replay
- [sale_outage_recovery_controller.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_outage_recovery_controller.dart)
  - retained recovery support for recorded manual claims

This means the regression is primarily a **UI/scope rollback**, not a full
deletion of the underlying order-lane machinery.

## Restore Rules

### Allowed UX

- offline user selects KHQR
- checkout captures a local outage/manual-claim order
- fulfillment queue routes that order into `External Claims`
- staff records proof and submits when online
- reviewer approves/rejects from order detail

### Forbidden UX

- `Place Order` / open-ticket creation
- generic unpaid ticket creation from cart
- reusing `dine_in` as a pay-later trigger
- reviving pay-later policy controls as part of this restore

## Contract Revalidation Boundary

Before runtime code changes, re-check current backend truth in:

- `integration/sale-order-v0.md`
- `integration/push-sync-v0.md`
- `integration/khqr-payment-v0.md`
- `integration/policy-v0.md`
- `integration/media-v0.md`

The restore should follow the current backend contract, not older prototype or
defense-scope assumptions.

## Phase 1 Findings

### Current active backend contract now supports a narrow restore

Backend has re-locked this as Option B:

- restore the outage/manual external-payment-claim lane
- keep generic pay-later/open-ticket disabled
- do not present this as offline KHQR gateway settlement

#### 1. Sale/order contract is now the primary authoritative lane contract
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
  - explicitly states:
    - this is one restored outage exception
    - it is not generic pay-later
    - it is not offline KHQR gateway settlement
  - active restore surfaces now include:
    - `POST /v0/orders` with `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
    - `GET /v0/orders?view=MANUAL_CLAIM_REVIEW`
    - `GET /v0/orders?sourceMode=MANUAL_EXTERNAL_PAYMENT_CLAIM`
    - `GET /v0/orders/:orderId/manual-payment-claims`
    - `POST /v0/orders/:orderId/manual-payment-claims`
    - approve / reject manual-claim endpoints
    - `POST /v0/media/images/upload` with `area = payment-proof`

#### 2. Authoritative create path is reconnect-time normal HTTP, not push replay
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
  - authoritative backend create for the exception lane:
    - `POST /v0/orders`
    - action key: `order.place`
    - active only when `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
  - generic/default `STANDARD` placement remains disabled and returns
    `ORDER_OPEN_TICKET_DISABLED`
- [push-sync-v0.md](/Users/mac/flutterProjects/modular/integration/push-sync-v0.md)
  - reconnect-submit manual-claim workflow is active
  - capture/replay operation is still out of push-sync scope

#### 3. KHQR contract stays online-first, with this lane treated as adjacent fallback
- [khqr-payment-v0.md](/Users/mac/flutterProjects/modular/integration/khqr-payment-v0.md)
  - active provider-backed KHQR settlement remains:
    - `POST /v0/checkout/khqr/initiate`
    - webhook or `POST /v0/payments/khqr/confirm`
  - restored manual-claim lane should not be labeled as KHQR settlement success
  - frontend must present it as outage/manual proof capture

#### 4. Active read surfaces are now explicit again
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
  - `GET /v0/orders` remains direct-checkout-first by default
  - claim review is surfaced explicitly through:
    - `view = MANUAL_CLAIM_REVIEW`
    - `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
  - order detail now supports:
    - `DIRECT_CHECKOUT`
    - `MANUAL_EXTERNAL_PAYMENT_CLAIM`

#### 5. Manual-claim lifecycle is active again
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
  - create claim:
    - `POST /v0/orders/:orderId/manual-payment-claims`
  - list claims:
    - `GET /v0/orders/:orderId/manual-payment-claims`
  - approve / reject:
    - reviewer roles only
  - state model:
    - order starts `OPEN`
    - claim statuses: `PENDING`, `APPROVED`, `REJECTED`
    - no sale exists before approval
    - approval creates/finalizes the non-cash sale and checks out the order
    - rejection keeps the order open and reviewable

#### 6. Payment-proof upload is active for this lane
- [media-v0.md](/Users/mac/flutterProjects/modular/integration/media-v0.md)
  - `POST /v0/media/images/upload`
  - use `area = payment-proof`
  - cashier upload is allowed for this lane
  - matching proof uploads are marked `LINKED` when referenced by claim create

#### 7. Policy must not gate the exception lane
- [policy-v0.md](/Users/mac/flutterProjects/modular/integration/policy-v0.md)
  - frontend must not use `saleAllowPayLater` to block this flow
  - no active branch policy flag is required for the restored exception lane
  - generic pay-later remains disabled separately

### Practical conclusion

Phase 1 result is now:
- the restore is contract-aligned again
- but it is explicitly narrow:
  - restore outage/manual external-payment-claim
  - do not restore generic pay-later/open-ticket
  - do not label the flow as offline KHQR settlement
- Phases 2-6 can proceed under this narrower boundary

## Phase Plan

## Phase 0 — Audit And Restore Boundary
- [x] Compare `spt5-sale-discount` against current `spt5-integration`
- [x] Identify what was intentionally removed from active UI
- [x] Confirm that core manual-claim plumbing still exists underneath
- [x] Lock the “restore claims, not pay-later” boundary

Output:
- restore target is precise and regression-resistant

## Phase 1 — Contract Revalidation
- [x] Re-read current sale / sync / KHQR / policy / media contracts
- [x] Confirm exact offline KHQR capture + proof-upload + claim-submit surfaces
- [x] Note contract changes since `spt5-sale-discount`

Output:
- restore is contract-aligned again, but only as a narrow outage exception lane

## Phase 2 — Cart-Side Outage Claim Restore
- [x] Restore the offline QR fallback CTA from cart
- [x] Restore user-safe outage/manual-claim messaging
- [x] Keep offline cash and outage claim capture clearly distinct
- [x] Keep pay-later/open-ticket CTA removed

Output:
- cart can capture outage/manual-claim orders again without reviving generic pay-later

## Phase 3 — Fulfillment Workspace Restore
- [x] Restore `External Claims` as an active workspace tab
- [x] Keep `Kitchen` queue paid-order focused
- [x] Keep claim rows out of the kitchen queue
- [x] Preserve `Void Requests` behavior

Output:
- claim discovery/work queue is reachable again without polluting kitchen flow

## Phase 4 — Order Detail Manual-Claim Restore
- [x] Re-enable manual-claim UI gates on order detail
- [x] Restore proof attach / submit actions as appropriate
- [x] Restore approve / reject review actions as appropriate
- [x] Keep legacy open-ticket settlement disabled

Output:
- full manual-claim workflow is reachable from order detail again

## Phase 5 — Recovery + Regression Hardening
- [x] Verify outage recovery still auto-submits recorded manual claims when online
- [x] Review sync/push expectations for restored claim lane
- [x] Add or update regressions for:
  - outage/manual-claim capture
  - `External Claims` tab visibility and filtering
  - manual-claim detail actions
  - no pay-later/open-ticket reintroduction

Output:
- restored flow is covered without reopening the wrong model

## Phase 6 — Validation
- [x] Run focused `flutter analyze`
- [x] Run focused `flutter test`
- [ ] Manual QA:
  - outage/manual-claim capture
  - claim proof attach
  - claim submit after reconnect
  - reviewer approve/reject
  - verify pay-later remains absent

Output:
- restore is complete and safe to merge

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 Audit And Restore Boundary | Completed | Current loss traced to the pay-first rollback, not to a random merge regression. |
| 1 Contract Revalidation | Completed | Backend re-enabled the exception lane narrowly: manual-claim outage restore is active again, generic pay-later remains disabled. |
| 2 Cart-Side Outage Claim Restore | Completed | Offline QR now captures a local external-claim outage order and no longer enqueues the deprecated claim-capture push op. |
| 3 Fulfillment Workspace Restore | Completed | `External Claims` is back for branch operators, while `Kitchen` and reviewer-only `Void Requests` stay separated. |
| 4 Order Detail Manual-Claim Restore | Completed | Order detail again supports proof capture, reconnect submit, and reviewer approve/reject without reviving legacy ticket settlement. |
| 5 Recovery + Regression Hardening | Completed | Existing outage recovery still auto-submits recorded claims; focused regressions were updated around cart, queue, and detail surfaces. |
| 6 Validation | Completed | Focused `flutter analyze` and `flutter test` passed; only manual QA remains outside this turn. |
