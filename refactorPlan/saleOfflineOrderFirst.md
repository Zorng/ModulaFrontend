# Sale Offline Order-First

Goal: adapt sale offline-first behavior to the backend’s new **order-first** model:
- offline outage flow captures **open order intent**
- non-cash outage fallback uses **manual external payment claim**
- payment settlement and final sale finalization stay **online**
- KHQR remains strictly online-only

This plan is intentionally separate from [offlineCommandQueue.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCommandQueue.md) because:
- `sale.finalize` is still not replay-safe
- sale offline support is no longer “full checkout replay”
- the frontend needs a distinct outage workflow, not just more `sync/push` coverage

---

## Backend rule (locked)

What frontend can rely on now:
- offline outage support is **order-first**
- service should continue through **open order capture**
- outage non-cash fallback is **`MANUAL_EXTERNAL_PAYMENT_CLAIM`**
- backend now supports a dedicated manual-claim order lane:
  - `POST /v0/orders` with `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
  - claim list/create/approve/reject endpoints on the order
- backend policy now separates:
  - ordinary pay later: `saleAllowPayLater`
  - outage manual-proof fallback: `saleAllowManualExternalPaymentClaim`

What frontend must not assume:
- `sale.finalize` is **not** offline-replayable
- KHQR is still **online-only**
- frontend must not fake non-cash outage payments as cash
- backend currently supports only `claimedPaymentMethod = KHQR` for the manual-claim lane

Practical frontend rule:
- **offline** -> capture order intent locally / queue order workflow
- **online** -> settle payment and finalize sale
- **offline non-cash** -> record `MANUAL_EXTERNAL_PAYMENT_CLAIM`, not fake cash

---

## Current frontend gap

Current sale flow is still finalize-first:
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - `checkout()` goes directly to `finalizeSale(...)`
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  - `finalizeSale(...)` is implemented
  - standard backend `placeOrder(...)` is now implemented
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  - local `createOrder(...)` exists, but it is not the offline-first sale workflow yet

So the frontend does **not** currently match the backend’s new outage contract.

Additional frontend/backend mismatch now confirmed:
- frontend **now has** the branch-policy seam for `saleAllowManualExternalPaymentClaim`
- frontend **now has** backend order creation for `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
- frontend **now has** UI for:
  - claim proof submission
  - claim pending review state
  - manager approve / reject actions
- frontend **now has** automatic reconnect/context recovery for recorded manual-claim outage orders
- remaining gap is cash outage reconnect materialization, because the live open-ticket settlement lane is still not implemented in frontend

---

## Scope lock

### In scope
- outage sale workflow design for **open order capture**
- offline-safe order capture state/queue design
- explicit non-cash outage fallback via `MANUAL_EXTERNAL_PAYMENT_CLAIM`
- reconnect handoff from offline order intent to online settlement/finalization
- sale UX rules for offline vs online checkout states

### Explicitly out of scope
- offline replay of `sale.finalize`
- KHQR offline behavior
- pretending external/manual claims are equivalent to finalized payment
- full implementation in this planning artifact

---

## Implementation phases

## Phase 0 — Inventory & Rule Lock
- [x] Map current sale finalize-first flow
- [x] Confirm existing order/open-ticket seams that can host outage capture
- [x] Lock frontend rules for:
  - offline cash outage
  - offline non-cash outage
  - online settlement handoff

Output:
- sale offline rule table

### Locked inventory

#### A. Current finalize-first flow

Current sale checkout still assumes online finalization:
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - `checkout()` always drives directly into `_repo.finalizeSale(...)`
  - KHQR checkout also converges into `finalizeSale(...)` after confirmation
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  - `finalizeSale(...)` is implemented
  - `placeOrder(...)` is still `UnimplementedError`

So the live frontend sale write lane is still **finalize-first**, not **order-first**.

#### B. Existing order/open-ticket seams already exist

The frontend already has the right domain shape for outage capture, but it is not yet wired as the real offline path:
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - `placeOrder()` exists and returns `SalePlaceOrderResult`
- [sale_checkout_repository_contract.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_checkout_repository_contract.dart)
  - `SalePlaceOrderCommand`
  - `SaleCheckoutOpenTicketCommand`
  - `SaleCancelOpenTicketCommand`
  - `SaleOpenTicketDetailDto`
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  - already models unpaid open tickets
  - already supports online settlement via `checkoutOpenTicket(...)`
- [order_viewmodel_test.dart](/Users/mac/flutterProjects/modular/test/sale/order_viewmodel_test.dart)
  - proves unpaid open tickets remain visible and settleable
- [mock_sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/mock_sale_repository.dart)
  - already models:
    - open ticket placement
    - add-items to open ticket
    - online open-ticket settlement
    - ticket cancellation

This means the frontend does **not** need a totally new domain concept for outage sale capture.
The existing open-ticket model is the correct host seam.

#### C. Important current mismatch: outage capture is tied to pay-later policy

Right now the order/open-ticket path is gated by normal pay-later access:
- [sale_access_gate.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_access_gate.dart)
  - `canPlacePayLater`
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - `placeOrder()` throws when `canPlacePayLater` is false
- [sale_cart_notifier_guard_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_cart_notifier_guard_test.dart)
  - locks that blocked behavior today

That is likely too narrow for outage support.

Backend’s new outage model is operational continuity, not ordinary “pay later”.
So outage order capture should be treated as its own workflow, not simply reuse current `payLaterDisabled` policy behavior unchanged.

#### D. Current frontend has no manual external payment claim seam yet

Search inventory confirms there is currently **no** frontend contract or UI seam for:
- `MANUAL_EXTERNAL_PAYMENT_CLAIM`
- manual external claim capture
- explicit outage non-cash payment claim metadata

So the non-cash outage fallback is a real new frontend addition, not just a toggle on existing checkout behavior.

### Locked sale outage rule table

| Scenario | Frontend action | What must happen | What must not happen |
|---|---|---|---|
| Offline cash outage | Capture open order intent locally | keep cart/service moving through open order capture | must not call `sale.finalize` offline |
| Offline non-cash outage | Capture open order intent locally and record `MANUAL_EXTERNAL_PAYMENT_CLAIM` | keep non-cash service truthful during outage | must not fake payment as cash |
| Offline KHQR | Block KHQR path | show KHQR as online-only | must not generate or pretend KHQR can queue offline |
| Reconnect after outage | Re-enter online settlement/finalization flow | settle payment truth online, then finalize sale | must not assume offline-captured order is already settled |

### Phase 0 conclusion

The correct implementation direction is now locked:

1. Reuse the existing **open-ticket/order** domain seam for outage capture.
2. Do **not** extend offline queueing toward `sale.finalize`.
3. Decouple outage sale capture from the ordinary `pay later` policy gate.
4. Add a new explicit frontend seam for `MANUAL_EXTERNAL_PAYMENT_CLAIM`.

---

## Phase 1 — Domain / State Model
- [x] Define offline sale intent states:
  - local open order captured
  - awaiting settlement
  - manual external payment claim recorded
  - settled/finalized online
- [x] Decide where local sale outage intents live:
  - sale feature cache
  - dedicated offline order queue
  - relation to existing `ordersProvider`

Output:
- frontend state model for sale outage capture

### Locked domain/state decisions

#### A. Outage sale intent is a persistent sale-domain object

Outage sale capture is not just a transient cart outcome.

It must survive:
- app restart
- branch switch away / back
- reconnect before settlement
- operator revisiting the order list later

So outage sale intent must **not** live only in:
- [sale_cart_state.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_state.dart)
  - this is the transient editor/cart state
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  - this is a UI projection/notifier, not durable storage

Locked rule:
- use a **dedicated persistent sale outage store** under `lib/features/sale/data/`
- project that durable outage state into the orders/read model

#### B. Outage sale intent should not reuse the generic offline command queue as its source of truth

The generic queue under [offline_command_queue_store.dart](/Users/mac/flutterProjects/modular/lib/core/sync/offline_command_queue_store.dart) is correct for replay-safe backend commands like:
- cash session
- attendance

But outage sale capture is different:
- it is operator-visible business state
- it has order lifecycle semantics, not just transport semantics
- it needs local read/query support before settlement

Locked rule:
- generic offline queue may later help transport a sale-related command
- but the **source of truth** for outage sale capture is a dedicated sale-domain store, not the generic queue row set

#### C. Existing sale/open-ticket objects already define most of the shape

The frontend already has the right core concepts:
- cart/editor state:
  - [sale_cart_state.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_state.dart)
- open ticket/order commands and DTOs:
  - [sale_checkout_repository_contract.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_checkout_repository_contract.dart)
- order list projection:
  - [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)

So the new state model should extend those concepts, not replace them.

#### D. Locked outage intent states

Every offline/outage sale intent should move through these states:

1. `LOCAL_OPEN_ORDER_CAPTURED`
- order intent is stored locally
- service can continue
- no payment settlement is claimed yet

2. `AWAITING_SETTLEMENT`
- order exists locally or has been rehydrated into the operator order list
- still requires online settlement/finalization

3. `MANUAL_EXTERNAL_PAYMENT_CLAIM_RECORDED`
- only for outage non-cash fallback
- operator explicitly recorded that payment was claimed externally during outage
- this is **not** equivalent to finalized payment truth

4. `SETTLEMENT_IN_PROGRESS`
- reconnect/online settlement is being attempted

5. `SETTLED_ONLINE`
- payment truth was settled online
- sale/order has moved into the normal online state

6. `FINALIZATION_FAILED`
- reconnect/settlement handoff failed
- order remains operator-visible and retryable

Important rule:
- `MANUAL_EXTERNAL_PAYMENT_CLAIM_RECORDED` is a **modifier/claim state** on top of the open order lifecycle, not proof that the sale is finalized

#### E. Minimum local fields for a durable outage sale intent

Each outage sale intent needs at least:
- `localIntentId`
- `tenantId`
- `branchId`
- `accountId`
- `saleId`
- provisional `openTicketId` / local order id
- `saleType`
- `paymentMethodRequested`
- `tenderCurrency`
- `cartLinesSnapshot`
- `totalsSnapshot`
- `state`
- `manualExternalPaymentClaim` metadata:
  - present / absent
  - recordedAt
  - optional note/reference
- `createdAt`
- `updatedAt`
- optional `settledSaleId`
- optional `receiptId`
- last error / retry metadata

Reason:
- operators need to see what was captured
- reconnect settlement needs enough information to continue truthfully
- manual external claims need explicit audit-like visibility

#### F. Relation to existing frontend state

Locked ownership split:

- `SaleCartState`
  - owns the working editor/cart only
  - after offline capture succeeds, cart can clear just like current `placeOrder()` success

- dedicated sale outage store
  - owns durable outage/open-order intent records

- `OrdersNotifier`
  - becomes the projection layer that merges:
    - online orders/open tickets from repository
    - local outage intents from the sale outage store

This preserves the existing order surface as the operator’s recovery/review area.

#### G. Relation to current `Order` model

The current [Order](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart) model is close, but not sufficient by itself.

It needs a way to distinguish:
- online unpaid open ticket
- local outage-captured open order
- local outage-captured open order with manual external payment claim

Locked rule:
- do not overload plain `ticketStatus = UNPAID` alone to mean all of those
- introduce explicit local provenance/status in the projection layer

### Phase 1 conclusion

The frontend state model is now locked as:

1. cart/editor stays transient
2. outage/open-order capture gets a dedicated persistent sale-domain store
3. orders screen becomes the unified projection surface
4. manual external payment claim is explicit metadata/state, not fake settlement
5. reconnect settlement updates the outage record instead of pretending offline capture already finalized payment

---

## Phase 2 — Capture Flow
- [x] Replace offline finalize behavior with offline open-order capture
- [x] Keep cart/service moving without pretending payment is finalized
- [x] Ensure operator can clearly distinguish:
  - open captured order
  - online-settled order
  - manual external payment claim

Output:
- outage order capture UX

### Locked capture-flow decisions

#### A. Offline sale capture must intercept the current primary action seam

The current cart primary action in
[sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart)
only branches into three paths:
- `QR` -> KHQR generate/view flow
- `dine_in` -> `placeOrder()`
- everything else -> `checkout()`

And the current payment surface in
[sale_cart_content.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart)
only exposes:
- `Cash`
- `QR Code`

Locked rule:
- when connectivity is offline, non-KHQR sale capture must **not** continue into `checkout()`
- instead, the primary action must switch to the outage open-order capture flow
- KHQR remains blocked offline and does not enter outage capture

#### B. Offline outage capture is not tied to dine-in / ordinary pay-later mode

Current UI behavior only reaches `placeOrder()` when:
- order type is `dine_in`
- `canPlacePayLater` is true

That is the wrong business rule for outage continuity.

Locked rule:
- offline outage capture is a **connectivity-continuity rule**, not a normal pay-later permission
- any non-KHQR outage sale that cannot finalize online may be captured as an outage open order
- do not require the operator to switch order type to `dine_in` just to continue service during outage
- current pay-later policy still applies to ordinary online open-ticket behavior, but it must not block outage capture

#### C. Cart action model during outage

Locked cart behavior:

| Context | Primary action behavior | Result |
|---|---|---|
| Online cash | normal `Checkout` | finalizes sale online |
| Online QR | KHQR flow | settles and finalizes online |
| Offline cash | capture outage open order | records local open order awaiting settlement |
| Offline non-cash outage fallback | capture outage open order + claim path handled in phase 3 | records truthful outage intent, not finalized payment |
| Offline KHQR | blocked | operator must use another path |

Important rule:
- outage capture success should clear the working cart, just like the current successful `placeOrder()` flow
- the success message must say the result is an **open order awaiting settlement**, not a finalized sale

#### D. Orders surface is the operator recovery surface

The existing orders surface already exists in:
- [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
- [order_card.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/widgets/order_card.dart)
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)

Locked rule:
- every successfully captured outage sale must reappear in the Orders surface
- this is where operators review, retry settlement, and distinguish local outage records from ordinary online open tickets

That keeps outage recovery inside an already-familiar operational screen instead of inventing a separate hidden queue UI.

#### E. Current order-card UX is not sufficient yet

Today [order_card.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/widgets/order_card.dart)
only distinguishes ordinary settleable unpaid open tickets with:
- status chip from `order.status`
- helper copy:
  - `Unpaid open ticket. Settlement remains available even when new pay-later orders are disabled.`

That is not enough for outage capture.

Locked rule:
- the order projection/card must explicitly distinguish:
  - ordinary online unpaid open ticket
  - locally captured outage open order
  - locally captured outage open order with manual external payment claim
- do **not** hide outage provenance behind the same unpaid ticket wording alone

Minimum visible operator cues:
- local/offline capture badge or status copy
- awaiting-settlement wording
- explicit manual external payment claim wording when present

#### F. Current order-status filter should not hide outage-captured orders

The current orders screen in
[order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
filters by:
- `pending`
- `in_prep`
- `ready`
- `delivered`
- `cancelled`

Locked rule:
- outage-captured open orders must remain visible through the existing orders workflow
- initial rollout should project them into the ordinary open/pending operational list instead of inventing a separate outage-only tab first
- if a local provenance badge is present, operators can still tell which rows require reconnect settlement

This keeps the first rollout operationally simple while preserving truthful visibility.

### Phase 2 conclusion

The outage capture UX is now locked as:

1. offline non-KHQR sale action intercepts the current cart primary action before `checkout()`
2. outage capture is allowed by connectivity need, not by ordinary pay-later policy alone
3. successful outage capture clears the cart but does **not** claim finalized payment
4. captured outage orders reappear in the existing Orders surface
5. order cards must visibly distinguish outage capture and later manual external payment claim from ordinary unpaid open tickets

---

## Phase 3 — Non-Cash Outage Fallback
- [x] Introduce explicit `MANUAL_EXTERNAL_PAYMENT_CLAIM` handling
- [x] Prevent fake-cash fallback for card/bank/manual external payments
- [x] Keep KHQR disabled offline

Output:
- truthful non-cash outage path

### Locked non-cash outage decisions

#### A. Manual external payment claim now has a backend-backed order lane

The current sale contracts show:
- [SalePlaceOrderCommand](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_checkout_repository_contract.dart)
  has no payment or claim fields
- [SaleCheckoutOpenTicketCommand](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_checkout_repository_contract.dart)
  only supports real online settlement inputs:
  - `paymentMethod`
  - `tenderCurrency`
  - `cashReceived`
  - `khqrMd5`

Locked rule:
- once connectivity is available for the fallback lane, frontend should use the backend-backed path:
  1. create order with `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
  2. create manual-payment claim on that order
- local outage storage still matters for fully offline capture
- but manual claim is no longer just a frontend-only concept once the order can be materialized online
- it is still **not** equivalent to settlement, receipt creation, or finalized payment truth

#### B. First rollout should not invent a fake non-cash cart payment tab

The current cart UI in
[sale_cart_content.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart)
only exposes:
- `Cash`
- `QR Code`

Locked rule:
- do **not** add a fake `Card`, `Bank`, or generic `External` payment tab just to represent outage behavior
- the first rollout keeps the existing cart payment tabs stable
- outage non-cash fallback is modeled as:
  1. capture the outage open order
  2. then create a backend manual payment claim against that captured order when the backend lane is reachable

This keeps the UI truthful and aligned with the backend’s order-first rule.

#### C. Manual external claim uses its own policy gate

Backend now separates:
- `saleAllowPayLater`
- `saleAllowManualExternalPaymentClaim`

Locked rule:
- manual external-claim availability must use `saleAllowManualExternalPaymentClaim`
- it must not piggyback on `saleAllowPayLater`
- disabling ordinary pay-later must not automatically disable the outage manual-proof fallback

This confirms the earlier phase-0 direction and gives the frontend a concrete policy seam to implement.

#### D. Manual external claim belongs on the order recovery surface

The current recovery surface already exists in:
- [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
- [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart)

And today [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart)
only supports settlement of unpaid tickets through:
- `Collect USD`
- `Collect KHR`

Locked rule:
- the manual external payment claim seam should live on the captured order / order-detail recovery path
- not as a hidden implicit side effect in the cart

Reason:
- the order already exists by then
- the operator can review the captured order before recording a claim
- the claim remains visible in the same place where later settlement retry will happen

#### E. Minimum manual external claim UX

For first rollout, the operator must be able to do all of the following on a captured outage order:
- upload/select proof image through the existing media upload lane
- record that external payment was claimed during outage
- optionally add note/reference text
- record customer reference
- record claimed amount / tender currency
- see when the claim was recorded
- distinguish the order from ordinary unpaid open tickets

Minimum visible cues after claim is recorded:
- `Manual external payment claimed` badge/callout
- recorded timestamp
- optional note/reference if present

This uses the metadata already locked in phase 1 and keeps the claim audit-like rather than invisible.

Important backend-bound rule:
- current backend support only allows `claimedPaymentMethod = KHQR`

So first rollout should:
- not present a generic claimed-payment-method picker
- hardcode this fallback lane as a KHQR/manual-proof claim flow

#### F. Pending claim is a locked review state

Backend now blocks these while a claim is pending:
- add items
- cancel order
- normal checkout

Error code:
- `ORDER_MANUAL_PAYMENT_CLAIM_PENDING`

Locked rule:
- frontend must surface pending-claim orders as a locked review state
- order detail must suppress ordinary settlement/edit/cancel actions while pending
- order list/detail should make it obvious the order is awaiting review, not ready for normal checkout

#### G. Manager approval / reject is the real finalization seam for this lane

Backend now supports:
- `POST /v0/orders/:orderId/manual-payment-claims/:claimId/approve`
- `POST /v0/orders/:orderId/manual-payment-claims/:claimId/reject`

Approval behavior:
- allowed only for `OWNER | ADMIN | MANAGER`
- backend creates and finalizes a KHQR sale
- order becomes `CHECKED_OUT`
- response includes receipt

Reject behavior:
- order remains open/unpaid
- claim becomes `REJECTED`

Locked rule:
- manager/admin/owner order detail must eventually expose `Approve` / `Reject`
- cashier-level users should see claim state, not approval controls
- receipt handling belongs to the approve-success path, not claim creation

#### H. Fake-cash fallback is explicitly forbidden

Locked rule:
- if the operator is handling a non-cash outage scenario, frontend must **not**:
  - switch the order to paid cash
  - auto-fill cash tender values
  - mark ticket status as if payment was collected
  - issue receipt/finalized success messaging

Instead:
- the order remains in the open/awaiting-settlement lifecycle
- the external payment claim is only a visible operator note/state

#### I. KHQR stays blocked offline

Current KHQR behavior is already online-dependent in:
- [sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart)
- [sale_khqr_popup.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_khqr_popup.dart)

Locked rule:
- offline `QR Code` selection must not degrade into manual external claim automatically
- frontend should keep KHQR explicitly blocked/offline-unavailable
- if the operator wants to continue serving during outage, they must use the outage open-order path and optionally record a manual external claim afterward

### Phase 3 conclusion

The truthful outage non-cash path is now locked as:

1. capture the order first
2. use the backend manual-claim lane when available:
   - create order with `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
   - attach proof through the claim endpoint
3. keep the order visibly open / awaiting review until approve succeeds
4. lock the order while claim review is pending
5. approve/reject belongs to manager/admin/owner review on order detail
6. receipt exists only after approve succeeds
7. keep KHQR blocked offline
8. never fake non-cash outage handling as paid cash

---

## Phase 4 — Reconnect Settlement Handoff
- [x] Define how fully offline-captured local outage orders materialize into backend open orders
- [x] Define when reconnect should create manual claims vs route to ordinary settlement
- [x] Define approval/finalization trigger after reconnect without double-finalize or stale claim state

Output:
- reconnect settlement lifecycle

### Locked reconnect-settlement decisions

#### A. Sale outage recovery is a separate lane from generic `sync/push`

The current reconnect lifecycle in
[app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)
already does:
1. `sync/push` replay for the generic offline queue
2. `sync/pull` convergence for cache-first modules

And the generic replay trigger in
[sync_push_trigger_controller.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_push_trigger_controller.dart)
only knows about queue-backed replay-safe commands.

Locked rule:
- outage sale intents are **not** replayed through the generic offline queue
- reconnect sale recovery needs its own sale-domain reconciler
- that reconciler runs **after** connectivity is restored and after the generic push/pull cycle has had a chance to stabilize workspace context

This preserves the earlier phase-1 decision that outage sale intent is business state, not just transport state.

#### B. Materialization happens in two stages

For fully offline-captured sale outage intents, reconnect recovery is:

1. **materialize backend order**
2. **continue with the appropriate online lane**

Locked rule:
- if a local outage record has no backend order id yet, reconnect must first create the backend open order
- only after a backend order exists may the frontend:
  - route to ordinary cash settlement, or
  - create the backend manual external payment claim

This avoids mixing local-only intent ids with online order/claim APIs.

#### C. Materialization strategy depends on outage path

Locked reconnect routing:

| Local outage path | Reconnect materialization | Next online step |
|---|---|---|
| Offline cash outage | create backend open order in ordinary open-order lane | operator performs normal online cash settlement from the order detail flow |
| Offline manual-claim outage | create backend open order with `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM` | create backend manual-payment claim when proof payload is available |

Important rule:
- reconnect should **not** auto-finalize either path immediately after order creation
- order creation only re-establishes server-side truth for the open order

#### D. Claim creation is conditional on having complete proof payload

Manual-claim reconnect handoff requires:
- backend order id
- proof image uploaded or uploadable
- claimed amount / currency
- customer reference / note when present

Locked rule:
- if the local outage record does not yet have a complete claim payload, reconnect must stop after creating the backend order
- the order remains visible as awaiting manual-claim completion
- frontend must not create a partial claim just because connectivity returned

This prevents broken review objects and keeps claim creation truthful.

#### E. Reconnect must preserve idempotent materialization state

Every outage record needs explicit materialization markers, at minimum:
- `backendOrderId`
- `materializedAt`
- optional `backendClaimId`
- optional `claimSubmittedAt`
- last recovery error

Locked rule:
- if `backendOrderId` already exists, reconnect must not create a second order
- if `backendClaimId` already exists, reconnect must not create a second claim
- repeated reconnect runs should resume from the last incomplete step, not restart the whole flow

This is the main anti-duplication rule for the sale outage reconciler.

#### F. No automatic finalization on reconnect

Current online settlement/finalization seam is still operator-driven in:
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  - `settleOpenTicket(...)`
- [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart)
  - `Collect USD`
  - `Collect KHR`

Locked rule:
- reconnect must not automatically call ordinary checkout/finalization after order materialization
- reconnect must not automatically approve manual external payment claims
- finalization remains an explicit online action:
  - cash path -> operator settles the open ticket
  - manual-claim path -> manager/admin/owner approves the claim

This keeps payment truth explicit and avoids hidden finalize side effects.

#### G. Pending claim blocks ordinary settlement after reconnect too

Backend already blocks ordinary checkout while a claim is pending:
- `ORDER_MANUAL_PAYMENT_CLAIM_PENDING`

Locked rule:
- once a backend claim is created, reconnect or later refresh must put the order into the locked review state
- ordinary cash settlement actions must stay hidden/disabled until:
  - the claim is rejected, or
  - the claim is approved and the order is checked out

This avoids stale UI offering settlement actions that backend will reject anyway.

#### H. Terminal outcomes

Locked reconnect terminal rules:

- **Cash settlement success**
  - order becomes normally checked out/finalized online
  - local outage record is marked `SETTLED_ONLINE` and can leave the active outage queue/projection

- **Manual claim approval success**
  - backend returns finalized sale + receipt
  - frontend must treat this as terminal finalization
  - local outage record is marked `SETTLED_ONLINE`
  - do **not** also run ordinary open-ticket settlement afterward

- **Manual claim rejection**
  - local/backend order remains open
  - claim lock is removed by backend rejection state
  - frontend keeps the order retryable for:
    - new claim submission
    - or ordinary cash settlement if operationally appropriate

- **Recovery failure**
  - record `FINALIZATION_FAILED` or a narrower recovery error
  - keep the order/operator visibility intact
  - allow later retry without duplicating order/claim creation

#### I. Orders refresh is the source of convergence after each step

Locked rule:
- after backend order creation, claim creation, approval, rejection, or cash settlement, frontend should refresh the orders/read model
- that refresh is what removes stale local assumptions from the operator surface

This matches the rest of the cache-first architecture and keeps sale recovery converged through real backend state once online again.

### Phase 4 conclusion

The reconnect settlement lifecycle is now locked as:

1. generic reconnect sync runs first for queue-backed modules
2. sale outage reconciler separately resumes local outage sale intents
3. offline-captured sale intents materialize into backend open orders first
4. cash and manual-claim paths then diverge:
   - cash -> operator settles online
   - manual-claim -> create claim, then await manager review
5. no reconnect path auto-finalizes or auto-approves
6. backend order/claim ids gate idempotent resume and prevent duplicates
7. orders refresh is the convergence surface after every online step

---

## Phase 5 — Validation
- [x] Widget/provider coverage for outage capture
- [x] Manual QA:
  - offline capture
  - reconnect settlement
  - non-cash outage fallback
  - KHQR stays online-only

Output:
- validated sale outage workflow

### Locked validation matrix

#### A. Provider/domain coverage required

The implementation must include focused provider/domain tests for:

1. outage capture decisioning
- offline cash routes to outage open-order capture
- offline KHQR is blocked
- outage capture is not blocked by ordinary `saleAllowPayLater`
- manual-claim availability follows `saleAllowManualExternalPaymentClaim`

2. durable outage store lifecycle
- local outage order record persists with:
  - cart snapshot
  - outage path
  - materialization markers
  - claim metadata
- successful offline capture clears the cart but preserves the durable record

3. reconnect reconciler
- local record without backend order id creates backend order once
- record with backend order id does not duplicate order creation
- manual-claim path with existing backend claim id does not duplicate claim creation
- incomplete proof payload stops after order materialization
- recovery failures remain retryable

4. role-sensitive review actions
- cashier cannot approve/reject claim
- manager/admin/owner can approve/reject claim
- approve transitions to finalized/receipt-backed terminal state
- reject returns order to open retryable state

#### B. Widget/UI coverage required

The implementation must include widget tests for:

1. cart/action surface
- offline cash primary action messaging
- offline KHQR blocked state
- outage capture success feedback says open order / awaiting settlement, not finalized sale

2. orders list surface
- outage-captured orders render distinct provenance from ordinary open tickets
- manual-claim pending badge/copy is visible
- settled-online orders no longer show outage recovery cues

3. order detail surface
- ordinary cash settlement actions are hidden/disabled when claim is pending
- claim creation form shows proof / amount / currency / reference / note
- manager/admin/owner review controls show approve/reject
- cashier sees read-only claim state

4. reconnect-driven refresh states
- materialized orders refresh into backend-backed order detail
- stale local assumptions are replaced after orders reload

#### C. Manual QA checklist

Minimum manual QA scenarios:

1. offline cash outage capture
- go offline
- build cart with non-QR payment
- capture outage order
- confirm cart clears
- confirm orders surface shows awaiting-settlement outage order
- reconnect
- confirm backend order materializes once
- confirm operator can settle online from order detail

2. offline non-cash manual-claim path
- capture outage order intended for manual external proof
- reconnect
- confirm backend order materializes with manual-claim lane
- submit proof image + amount + currency + optional note/reference
- confirm order becomes pending review
- confirm ordinary checkout/add/cancel actions are locked

3. manager review path
- open pending-claim order as manager/admin/owner
- approve claim
- confirm backend returns finalized sale + receipt
- confirm order becomes checked out
- confirm receipt actions become available

4. rejection path
- reject pending claim
- confirm order remains open/unpaid
- confirm claim state becomes rejected
- confirm order is again eligible for retry flow instead of staying locked

5. anti-duplication / reconnect resilience
- reconnect multiple times during incomplete recovery
- confirm no duplicate backend order creation
- confirm no duplicate claim creation

6. KHQR boundary
- while offline, confirm QR path remains blocked
- confirm app does not silently convert QR intent into cash or fake finalization

#### D. Success criteria

The sale outage workflow is considered validated only when all of the following are true:
- outage capture keeps service moving without fake payment truth
- manual external claim follows the dedicated backend lane and policy
- pending claim produces a locked review state
- approval is the only path that yields finalized receipt for the manual-claim lane
- reconnect recovery is idempotent and does not duplicate orders/claims
- KHQR remains online-only

### Phase 5 conclusion

The validation target is now locked:

1. provider/domain tests must cover outage capture, durable state, reconnect reconciliation, and role-sensitive review
2. widget tests must cover cart, orders list, order detail, and pending-claim lock states
3. manual QA must prove cash outage capture, manual-claim review, approval/rejection, reconnect idempotency, and KHQR boundaries
4. the workflow is not considered done unless it preserves truthful payment state from outage capture through final approval

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Current finalize-first mismatch, reusable open-ticket seams, pay-later gate conflict, and missing manual external claim seam are now locked |
| 1 | Completed | Durable outage sale intent model, ownership split, and relation to cart/orders/manual external payment claim are now locked |
| 2 | Completed | Cart interception, outage capture action model, and Orders-surface recovery/provenance rules are now locked |
| 3 | Completed | Backend-backed manual-claim lane, separate policy gate, pending-review lock state, manager approval path, and KHQR offline boundary are now locked |
| 4 | Completed | Reconnect materialization, cash-vs-manual-claim routing, no-auto-finalize rules, and anti-duplication markers are now locked |
| 5 | Completed | Provider/widget validation matrix, manual QA scenarios, and success criteria are now locked |
