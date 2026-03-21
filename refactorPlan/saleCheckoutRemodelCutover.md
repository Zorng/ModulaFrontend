# Sale Checkout Remodel Cutover

Goal: align the frontend sale cart and fulfillment behavior to the updated backend remodel:
- `cart` = frontend-local temporary state only
- `order` = operational + fulfillment truth
- `sale` = payment + financial truth

This cutover is required because the current frontend still mixes:
- legacy server-side sale drafts
- quick-pay checkout as if it were sale-only
- order fulfillment reads that do not yet follow the merged fulfillment queue rules

Canonical sources:
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
- [khqr-payment-v0.md](/Users/mac/flutterProjects/modular/integration/khqr-payment-v0.md)

Important contract rule:
- for checkout remodel, [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md) is the source of truth
- [khqr-payment-v0.md](/Users/mac/flutterProjects/modular/integration/khqr-payment-v0.md) still contains legacy live `/v0/payments/khqr` details plus a non-implemented draft section, so it must not drive the quick-checkout flow

---

## Scope lock

### In scope
- remove legacy server-draft dependence from the sale cart
- keep pay-now cash on `POST /v0/checkout/cash/finalize`
- keep quick KHQR on `/v0/checkout/khqr/*`
- treat quick-pay results as order-backed for fulfillment
- move fulfillment queues to `GET /v0/orders?view=FULFILLMENT_ACTIVE`
- keep open-ticket/pay-later flows on `/v0/orders*`

### Out of scope
- offline settlement replay for sale/order
- KHQR offline support
- receipt redesign
- broader sale UX redesign unrelated to the remodel

---

## Phase 0 — Inventory & Rule Lock
- [x] Map current cart/draft drift against the new contract
- [x] Lock the new frontend rules for:
  - local cart behavior
  - quick cash checkout
  - quick KHQR checkout
  - fulfillment queue reads

Output:
- exact seam inventory and cutover rules

### Locked inventory

#### 1. Cart is still server-draft-backed in frontend

Current drift:
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - `_ensureSaleId()`
  - `addSelection()` calling `_repo.addItem(...)`
  - `updateQuantity()` calling `_repo.updateItemQuantity(...)`
  - `setSaleType()` recreating a backend draft and replaying lines
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  - `ensureDraft()`
  - `addItem()`
  - `updateItemQuantity()`
  - `removeItem()`
- [sale_api.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_api.dart)
  - `POST /v0/sales/drafts`
  - other legacy draft endpoints

Why this is wrong now:
- backend now defines `cart` as frontend-local only
- server-side draft mutations are not the canonical checkout lane anymore

#### 2. Quick cash checkout lane is already mostly correct

What is already aligned:
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  `finalizeSale(...)` already routes cash to:
  - `POST /v0/checkout/cash/finalize`

What still needs to change around it:
- frontend must stop assuming quick cash is “sale only”
- quick cash responses now produce an `orderId` that becomes the fulfillment anchor

#### 3. Quick KHQR checkout is mixed between new and old models

What is already aligned:
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  `generateKhqrAttempt(...)` already uses:
  - `POST /v0/checkout/khqr/initiate`
  - `GET /v0/checkout/khqr/intents/:intentId`
  - `POST /v0/checkout/khqr/intents/:intentId/cancel`

What is still risky/needs review:
- frontend still carries `saleId` through cart/KHQR state as if quick KHQR were sale-backed at initiate
- quick KHQR finalization semantics must be treated as order-backed after successful confirmation

#### 4. Fulfillment queue reads are not yet using the merged queue view

Current drift:
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  currently loads orders through `getOrders(...)` without the new `view=FULFILLMENT_ACTIVE` intent
- [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
  still models the screen as status-filter-first instead of a merged active fulfillment queue

Why this matters:
- quick-pay direct checkouts are often `CHECKED_OUT` immediately
- they still need fulfillment updates
- `status = OPEN` alone is no longer the right queue definition

#### 5. Legacy naming still leaks sale-oriented detail seams

Current drift:
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  `getOpenTicketDetail({required String saleId})`
- [sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart)
  still passes `saleId` into the open-ticket detail dialog

This remains separate from the cart-local cutover, but it is part of the remodel cleanup backlog.

### Locked frontend rules

1. Cart mutations must be local-only.
- no draft creation
- no backend line sync while editing the cart

2. Quick pay-now cash must use `POST /v0/checkout/cash/finalize`.
- success creates both financial truth and operational order truth
- frontend must retain `orderId` for fulfillment surfaces

3. Quick pay-now KHQR must stay on `/v0/checkout/khqr/*`.
- initiate creates intent, not sale
- confirmed/finalized quick KHQR must be treated as order-backed afterward

4. Pay-later remains on `/v0/orders*`.
- order create/add-items/checkout continue to use order endpoints

5. Fulfillment queue screens should read from:
- `GET /v0/orders?view=FULFILLMENT_ACTIVE`

### Phase 0 conclusion

The first safe implementation slice is now locked:
- remove the sale cart’s dependency on legacy server drafts
- keep checkout/payment writes on the new lanes that already exist
- only after that, retune the fulfillment/read surfaces

---

## Phase 1 — Local Cart Cutover
- [x] Remove legacy draft syncing from [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
- [x] Sanitize restored/persisted cart state so stale `saleId` and remote line ids do not revive old draft behavior
- [x] Keep checkout and pay-later command building from local cart lines

Output:
- sale cart is frontend-local again

### Phase 1 result

What changed:
- [sale_cart_state.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_state.dart)
  now supports explicitly clearing stale `saleId` during cart normalization
- [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  no longer:
  - creates backend drafts while editing the cart
  - syncs add/update/remove line mutations to legacy draft endpoints
  - requires a draft id before pay-later order placement
- persisted cart restore now sanitizes:
  - stale `saleId`
  - stale remote line item ids
- pay-later and checkout command payloads still build from local cart lines
- quick KHQR initiate remains on the local-cart checkout lane; status/cancel still tolerate current attempt state for compatibility until the later KHQR-specific remodel slice

Validation:
- `flutter analyze lib/features/sale/ui/viewmodels/sale_cart_state.dart lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart test/sale/sale_cart_notifier_guard_test.dart`
- `flutter test test/sale/sale_cart_notifier_guard_test.dart test/sale/sale_cart_khqr_state_test.dart test/sale/sale_cart_readonly_test.dart`

Phase 1 conclusion:
- the sale cart is no longer draft-backed during normal editing
- the next cutover seam is the quick checkout / fulfillment alignment itself

---

## Phase 2 — Quick Checkout Alignment
- [x] Verify pay-now cash uses only `POST /v0/checkout/cash/finalize`
- [x] Verify quick KHQR uses only `/v0/checkout/khqr/*` for the cart flow
- [x] Make post-checkout state retain the order anchor needed for fulfillment visibility

Output:
- quick cash + quick KHQR align with the remodel

### Phase 2 result

What changed:
- cash quick checkout stays on `POST /v0/checkout/cash/finalize` and now preserves the backend `orderId` anchor into cart success state
- quick KHQR cart flow no longer depends on the legacy manual confirm lane during checkout
- KHQR checkout now:
  - polls `GET /v0/checkout/khqr/intents/:intentId`
  - waits for backend materialization of `sale + order`
  - hydrates final checkout success from `GET /v0/sales/:saleId` and receipt read
- mock KHQR behavior and cart tests now match the new contract rule:
  - no `saleId` at initiate
  - `saleId` appears only after backend finalization

Validation:
- `flutter analyze lib/features/sale/data/sale_checkout_repository_contract.dart lib/features/sale/data/dto/sale_dto.dart lib/features/sale/data/sale_mappers.dart lib/features/sale/data/sale_api.dart lib/features/sale/data/sale_repository.dart lib/features/sale/data/mock_sale_repository.dart lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart test/sale/sale_cart_khqr_state_test.dart test/sale/sale_repository_finalize_payload_test.dart`
- `flutter test test/sale/sale_mapper_test.dart test/sale/sale_cart_khqr_state_test.dart test/sale/sale_checkout_mock_repository_test.dart test/sale/sale_repository_finalize_payload_test.dart test/sale/sale_cart_notifier_guard_test.dart test/sale/sale_cart_readonly_test.dart`

Phase 2 conclusion:
- quick cash and quick KHQR now follow the remodel contract closely enough to move the cutover focus to fulfillment reads

---

## Phase 3 — Fulfillment Queue Cutover
- [x] Extend the order read lane to support `view=FULFILLMENT_ACTIVE`
- [x] Move fulfillment-oriented screens to the merged active queue semantics
- [x] Ensure quick-pay direct-checkout orders still appear while prep is active

Output:
- fulfillment queue reads match backend order truth

### Phase 3 result

What changed:
- order query DTO/API/repository now support `view=FULFILLMENT_ACTIVE`
- the Orders surface now loads the merged active fulfillment queue by default instead of relying on `status = OPEN` semantics alone
- the Orders page no longer offers a misleading `Cancelled` chip on the active queue surface
- quick-pay direct-checkout orders remain visible in the same queue while their fulfillment work is still active

Validation:
- `flutter analyze lib/features/sale/data/sale_checkout_repository_contract.dart lib/features/sale/data/sale_api.dart lib/features/sale/data/sale_repository.dart lib/features/sale/ui/viewmodels/order_viewmodel.dart lib/features/sale/ui/view/order/order_page.dart test/sale/order_viewmodel_test.dart test/sale/sale_repository_order_lane_test.dart test/sale/order_page_test.dart test/sale/sale_cart_panel_khqr_test.dart`
- `flutter test test/sale/order_viewmodel_test.dart test/sale/order_page_test.dart test/sale/sale_repository_order_lane_test.dart test/sale/sale_cart_panel_khqr_test.dart`

Phase 3 conclusion:
- the fulfillment queue surface now follows backend order truth closely enough to move on to the remaining naming cleanup and offline-first follow-through

---

## Phase 4 — Legacy Order Detail Naming Cleanup
- [x] Replace sale-oriented open-ticket detail naming/seams with order-oriented ones
- [x] Remove any remaining sale-id assumptions from order detail/cart bridge surfaces

Output:
- order detail naming follows order truth consistently

### Phase 4 result

What changed:
- the cart-side open-ticket detail bridge now requests detail by `orderId`, not `saleId`
- open-ticket detail DTOs now expose `orderId` instead of a misleading `saleId`
- pay-later success feedback no longer stores a fake “placed sale id” just to reopen the ticket detail
- the cart success banner now reopens ticket detail through the real open-ticket/order anchor only

Validation:
- `flutter analyze lib/features/sale/data/sale_checkout_repository_contract.dart lib/features/sale/data/sale_repository.dart lib/features/sale/data/mock_sale_repository.dart lib/features/sale/ui/viewmodels/sale_cart_state.dart lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart test/sale/sale_checkout_mock_repository_test.dart test/sale/sale_cart_notifier_guard_test.dart`
- `flutter test test/sale/sale_checkout_mock_repository_test.dart test/sale/sale_cart_notifier_guard_test.dart test/sale/sale_cart_readonly_test.dart test/sale/sale_cart_panel_khqr_test.dart`

Phase 4 conclusion:
- the remaining cart/order bridge surfaces now follow order truth instead of reusing stale sale-id terminology

---

## Phase 5 — Sale Offline-First Follow-through
- [x] Rebase live pay-later detail/settlement seams on the remodel where needed
- [ ] Keep offline cash/manual-claim behavior aligned to order-first recovery
- [x] Ensure quick-pay remains online-only for actual settlement

Output:
- sale offline-first work sits on the corrected checkout/order lifecycle

### Phase 5 result

What changed:
- the live API repository now supports:
  - `GET /v0/orders/:orderId` for ticket detail
  - `POST /v0/orders/:orderId/checkout` for open-ticket settlement
- the cart-side open-ticket dialog now reflects truthful order data:
  - payable totals derived from order lines
  - line count instead of the legacy "batches" concept
- offline cash outage recovery now follows the order-first lane too:
  - materialize backend open order first
  - then settle it through `POST /v0/orders/:orderId/checkout`
- the offline-first sale recovery work no longer depends on mock-only ticket detail/checkout support in the live repository

Validation:
- `flutter analyze lib/features/sale/data/sale_api.dart lib/features/sale/data/sale_repository.dart lib/features/sale/data/mock_sale_repository.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart test/sale/sale_api_write_lane_test.dart test/sale/sale_repository_order_lane_test.dart test/sale/sale_repository_finalize_payload_test.dart test/sale/sale_checkout_mock_repository_test.dart`
- `flutter test test/sale/sale_api_write_lane_test.dart test/sale/sale_repository_order_lane_test.dart test/sale/sale_repository_finalize_payload_test.dart test/sale/sale_checkout_mock_repository_test.dart`

Phase 5 conclusion:
- the live pay-later detail and checkout seams now sit on the real order lane
- offline cash and manual-claim recovery both now sit on the order-first lifecycle
- remaining follow-through is mainly recovery automation and manual QA, not missing online order primitives

---

## Phase 6 — Validation
- [x] Focused analyzer/test coverage for the checkout remodel slices landed so far
- [ ] Manual QA:
  - quick cash checkout
  - quick KHQR checkout
  - pay-later ticket flow
  - fulfillment queue visibility for direct checkout orders
  - offline outage order recovery remains intact

Output:
- validated checkout remodel cutover

### Phase 6 status

Automated validation complete:
- `flutter analyze lib`
- `flutter test test/sale/sale_api_write_lane_test.dart test/sale/sale_repository_finalize_payload_test.dart test/sale/sale_repository_order_lane_test.dart test/sale/sale_checkout_mock_repository_test.dart test/sale/order_viewmodel_test.dart test/sale/order_detail_page_test.dart`

Known non-blocking backlog after validation scan:
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  still leaves `addItemsToOpenTicket(...)` and `cancelOpenTicket(...)` unimplemented in the live API repository
- current sale UI has no live callers for those seams yet, so they do not block the remodeled cart, quick checkout, fulfillment queue, or outage recovery flows that are currently exposed

Manual QA still required on staging/browser:
- quick cash checkout creates a visible fulfillable order anchor
- quick KHQR finalization produces the same order-backed fulfillment behavior
- pay-later ticket placement -> view ticket -> settle ticket works live
- offline cash outage capture -> reconnect -> settle captured cash order works live
- offline manual-claim capture -> reconnect -> submit claim still works live

Current staging blocker:
- quick cash checkout is currently blocked by backend constraint failure on order-anchor materialization
- feedback packet:
  - [saleQuickCashConstraintFeedback.md](/Users/mac/flutterProjects/modular/refactorPlan/saleQuickCashConstraintFeedback.md)

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Inventory locked against the updated backend remodel |
| 1 | Completed | Cart is local-only again; stale draft ids are sanitized on restore/mutation |
| 2 | Completed | Cash and quick KHQR checkout lanes now align to the remodel; order anchor retained on success |
| 3 | Completed | Orders surface now reads the merged `FULFILLMENT_ACTIVE` queue by default |
| 4 | Completed | Cart/order detail bridge now uses order identity instead of sale-id aliases |
| 5 | Completed | Live order detail + open-ticket checkout landed; outage cash/manual-claim recovery now follows the order-first lane |
| 6 | In progress | Automated validation complete; staging/manual QA still pending |
