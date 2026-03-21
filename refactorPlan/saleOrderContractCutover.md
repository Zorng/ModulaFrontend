# Sale / Order Contract Cutover

Goal: align the frontend sale/order implementation to the current backend contract in [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md) before continuing deeper sale offline-first work.

Why this must happen now:
- frontend still reads Orders from the sale list lane
- frontend still updates fulfillment through the sale lane
- offline-first sale recovery depends on a correct order lifecycle

This is a contract cutover, not a redesign.

---

## Locked source of truth

Use [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md) as the canonical contract for this work.

Key backend rules already confirmed there:
- `GET /v0/orders` is the order list lane
- `GET /v0/orders/:orderId` is the order detail lane
- `PATCH /v0/orders/:orderId/fulfillment` updates fulfillment status
- `GET /v0/sales` is the finalized financial-record lane
- checkout and pay-later/order lifecycles are separate

---

## Current frontend drift

### 1. Orders page is reading the wrong lane
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  - `getOrders(...)` currently proxies through `listSales(...)`
- This means the Orders UI is built from sale records, not order records

### 2. Fulfillment update is hitting the wrong endpoint
- [sale_api.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_api.dart)
  - `updateFulfillmentStatus(...)` currently patches `'/v0/sales/:saleId/fulfillment'`
- Contract says it must patch:
  - `PATCH /v0/orders/:orderId/fulfillment`

### 3. Viewmodel identity is blurred
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  - `updateStatus(...)` still resolves and sends a sale-oriented id
- The current UI model mixes:
  - order identity
  - sale identity
  - open-ticket identity

### 4. Backend summary shape may still need feedback
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
  - current `GET /v0/orders` example is minimal
- backend now includes `fulfillmentStatus` in the list payload, which removes one gap
- frontend still likely needs richer order summary data to render the current Orders list cleanly without detail fetch fan-out

---

## Scope lock

### In scope
- order list contract cutover
- fulfillment status update cutover
- order vs sale identity cleanup in the Orders surfaces
- backend feedback list for any missing order summary fields

### Out of scope
- general sale UX redesign
- receipt redesign
- new order-management features beyond contract alignment
- KHQR flow redesign

---

## Phase 0 — Inventory Against Contract
- [x] Map every current frontend call site using:
  - `listSales`
  - `getOrders`
  - `updateFulfillmentStatus`
  - order detail loading
- [x] Classify each one as:
  - should stay on `/v0/sales`
  - should move to `/v0/orders`
- [x] Lock exact ownership of ids in UI/domain:
  - `orderId`
  - `saleId`
  - `openTicketId`

Output:
- inventory table of sale-lane vs order-lane consumers

### Phase 0 inventory

#### A. Current consumers mapped against the contract

| Consumer | Current frontend call | Current lane | Correct lane | Notes |
|---|---|---|---|---|
| [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart) `load()` | `_repo.getOrders(...)` -> [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart) `getOrders()` | built from `listSales()` | `/v0/orders` | This is the main read-lane drift. Orders UI is currently sale-backed. |
| [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart) `updateStatus()` | `_repo.updateFulfillmentStatus(saleId: ...)` | `/v0/sales/:saleId/fulfillment` | `PATCH /v0/orders/:orderId/fulfillment` | Wrong entity and wrong endpoint. This is the current 404 source. |
| [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart) `settleOpenTicket()` | `_repo.checkoutOpenTicket(openTicketId: ...)` | contract already models order settlement | `POST /v0/orders/:orderId/checkout` | This should stay on the order lane. `openTicketId` is a legacy alias here. |
| [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart) | watches `ordersProvider` | indirectly sale-backed today | `/v0/orders` via repo cutover | Orders page itself is structurally correct, but its provider source is wrong. |
| [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart) | watches `ordersProvider`; status and settlement actions operate on `Order` model | mixed | `/v0/orders/*` for order actions | Detail page is conceptually order-driven, but currently receives blurred identities from the provider. |
| [sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart) `_showOpenTicketDialog()` | `cartNotifier.getOpenTicketDetail(saleId: saleId)` | legacy open-ticket detail seam | `GET /v0/orders/:orderId` | This should stop loading open-ticket detail by sale id. |
| [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart) `getOpenTicketDetail()` | `_repo.getOpenTicketDetail(saleId: saleId)` | legacy open-ticket detail seam | `GET /v0/orders/:orderId` | Repository contract still exposes sale-oriented naming here. |
| [view_carts_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/view_carts/view_carts_page.dart) | `repo.listSales(...)` | `/v0/sales` | `/v0/sales` | This is correct. It is a finalized sale/history surface, not an Orders surface. |

#### B. Locked identity ownership

`orderId`
- canonical backend identity for `/v0/orders/*`
- used for:
  - order list/detail
  - fulfillment updates
  - order checkout
  - order cancel
  - manual payment claim list/create/approve/reject

`saleId`
- canonical backend identity for `/v0/sales/*`
- used for:
  - finalized sale history
  - receipts
  - void / sale-financial lifecycle
- may be linked from an order after settlement/finalization, but it is not the order mutation id

`openTicketId`
- legacy frontend alias for an unpaid order id
- should not remain a separate backend identity concept
- during the cutover, repository/viewmodel code should treat it as an order-lane id and eventually collapse naming toward `orderId`

`localIntentId`
- local-only outage identity
- must stay separate from both `orderId` and `saleId`

#### C. Contract-based conclusions

1. Orders and sales are separate read lanes.
- `Orders` UI must be backed by `/v0/orders`
- `Carts` / finalized sale history must stay on `/v0/sales`

2. Fulfillment is an order mutation, not a sale mutation.
- all fulfillment status updates must move to `PATCH /v0/orders/:orderId/fulfillment`

3. The current frontend `Order` model is overloading ids.
- today it mixes:
  - `id`
  - `saleId`
  - `openTicketId`
  - local outage ids
- phase 3 of this cutover must make order actions explicitly order-id driven

4. Backend feedback is likely still needed for `GET /v0/orders`.
- the current example payload in [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md) is minimal
- `fulfillmentStatus` is now present in the order list payload, which reduces the gap
- the current Orders list UI still likely needs richer summary fields such as totals and line summary to avoid degrading the card or adding detail fetch fan-out

### Phase 0 conclusion

The main cutover rule is now locked:
- if the user is looking at or mutating an **order**, frontend must use the `/v0/orders` lane and an `orderId`
- if the user is looking at or mutating a **finalized sale**, frontend must use the `/v0/sales` lane and a `saleId`

This is the prerequisite for continuing sale offline-first safely.

---

## Phase 1 — DTO / API Contract Split
- [x] Add explicit order-list and order-detail DTOs if current sale DTOs are being reused incorrectly
- [x] Implement `GET /v0/orders`
- [x] Implement `GET /v0/orders/:orderId` if needed for the current detail path
- [x] Implement `PATCH /v0/orders/:orderId/fulfillment`
- [x] Stop treating fulfillment updates as sale mutations

Output:
- `sale_api.dart` reflects the backend order endpoints cleanly

### Phase 1 result

What was added:
- explicit order-lane DTOs in [sale_dto.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/dto/sale_dto.dart):
  - order list item/page
  - order detail
  - order line
  - fulfillment batch read/update
  - manual payment claim read
- explicit order-lane API methods in [sale_api.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_api.dart):
  - `listOrders(...)`
  - `getOrderDetail(...)`
  - `updateOrderFulfillmentStatus(...)`

Fulfillment mutation cutover:
- repository/update-status code no longer targets the sale fulfillment route
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart),
  [sale_checkout_repository_contract.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_checkout_repository_contract.dart),
  [mock_sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/mock_sale_repository.dart),
  and [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  now treat fulfillment updates as order mutations

Important boundary:
- `getOrders(...)` is still repository-proxied through the sale list lane
- `getOpenTicketDetail(...)` is still a legacy contract seam
- so phase 1 fixes the transport/DTO layer, but not the full read-lane behavior yet

Validation:
- focused analyzer and tests passed for:
  - order DTO parsing
  - order API paths
  - fulfillment patch path
  - existing order viewmodel and mock repository compile/runtime coverage

---

## Phase 2 — Repository Cutover
- [x] Make `getOrders(...)` use the real order list endpoint
- [x] Make fulfillment updates target order ids, not sale ids
- [x] Keep `/v0/sales` only for sale-history / finalized-sale reads
- [x] Preserve existing offline outage projection merge behavior where possible

Output:
- repository boundary matches backend lifecycle split

### Phase 2 result

Repository cutover:
- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  `getOrders(...)` now reads from `GET /v0/orders`
- it no longer proxies through `listSales(...)`
- after the backend list expansion, it no longer enriches each row with
  `GET /v0/orders/:orderId` just to build the Orders card summary
- `/v0/sales` remains the finalized sale/history lane

Expanded list mapping:
- the repository now builds Orders list summaries directly from the expanded
  `GET /v0/orders` payload:
  - `fulfillmentStatus`
  - `totalUsdExact`
  - `linesPreview`
  - `checkedOutAt`
  - `paymentMethod`
  - `manualPaymentClaimId`
  - `manualPaymentClaimStatus`
- `totalKhrExact` is still client-derived from the current branch policy as a temporary fallback because backend does not expose authoritative order-list KHR totals yet

Important boundary:
- backend feedback is still needed on the remaining order-list gaps:
  - `saleType`
  - authoritative `totalKhrExact`
- phase 3 still needs to clean the `Order` model and UI identity assumptions so order actions become fully order-id driven without compatibility aliasing

Validation:
- focused analyzer passed for the sale DTO/API/repository/viewmodel seam
- focused tests passed for:
  - order list/detail DTO parsing
  - order API read/update paths
  - repository order-lane enrichment/fallback behavior
  - existing order viewmodel and mock repository behavior

---

## Phase 3 — Viewmodel / UI Identity Cleanup
- [x] Update [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart) so order actions operate on `orderId`
- [x] Audit [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart), [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart), and [order_card.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/widgets/order_card.dart)
- [x] Ensure local outage orders can still coexist with backend order summaries without identity collisions

Output:
- Orders surfaces are explicitly order-driven, not sale-driven

### Phase 3 result

Identity cleanup:
- [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart)
  now treats Orders as order-driven:
  - remote loads require `orderId`, not `saleId`
  - fulfillment updates use explicit order identity keys
  - local outage orders win merge collisions against generic remote summaries when they share a backend `orderId`
- local outage orders no longer fake `saleId = orderId`
- order-summary projection now derives open-ticket behavior from ticket status instead of comparing `saleId` vs `orderId`

UI cleanup:
- [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
  now passes an explicit order identity key into:
  - status updates
  - detail navigation
- local outage orders no longer expose the generic fulfillment-status tap path
- [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart)
  now resolves the selected record by identity key, not by display number
  - this prevents collisions between local outage records and backend order summaries
  - detail summary now surfaces `Order ID` / `Backend Order ID` explicitly instead of only relying on the legacy open-ticket label

Important boundary:
- full detail fetch is still a separate future seam if the order detail screen needs more than the list payload preview
- backend feedback is still needed for the remaining list gaps (`saleType`, authoritative `totalKhrExact`)
- sale cart / legacy open-ticket detail naming is still a separate cleanup seam outside this phase

Validation:
- focused analyzer passed for:
  - repository order bridge
  - order viewmodel
  - order page/detail surfaces
- focused tests passed for:
  - repository order-lane behavior
  - order notifier merge/identity behavior
  - order detail actions
  - order page rendering

---

## Phase 4 — Backend Feedback Packet
- [x] Compare current Orders UI needs against the `GET /v0/orders` example payload
- [x] List missing fields needed for clean summary rendering, if any
- [x] Prepare exact feedback for backend:
  - required
  - optional
  - can be derived client-side

Output:
- concrete backend feedback note if contract shape is insufficient

### Phase 4 result

Backend feedback packet prepared:
- [saleOrderListFeedbackPacket.md](/Users/mac/flutterProjects/modular/refactorPlan/saleOrderListFeedbackPacket.md)

Locked comparison result:
- backend expanded `GET /v0/orders` enough for the current Orders list surface
- frontend has now removed the repository `GET /v0/orders/:orderId` fan-out for list cards
- the remaining backend gap is narrower and no longer blocks the list cutover

Still missing for clean summary rendering:
- required:
  - `saleType`
  - `totalKhrExact`
- optional:
  - none currently blocking the list surface
- derivable client-side:
  - `ticketStatus`
  - status label/color
  - open-ticket semantics
  - order identity key

Conclusion:
- the contract update materially improved the order-list lane
- backend feedback is now reduced to:
  - authoritative `saleType`
  - authoritative `totalKhrExact`
- repository list loading is already cut over cleanly; remaining feedback is about correctness/polish, not basic usability

---

## Phase 5 — Regression + QA
- [x] Add tests for:
  - order list parsing
  - fulfillment update endpoint path
  - order id vs sale id usage
  - outage/local order merge after real order-list cutover
- [ ] Manual QA:
  - online cash checkout visibility in Orders
  - open-ticket / pending payment visibility
  - fulfillment status change no longer 404s
  - manual-claim outage order still merges correctly

Output:
- validated sale/order contract cutover

### Phase 5 result

Automated regression coverage is now in place for:
- order list parsing against the expanded `GET /v0/orders` payload
- fulfillment update transport on the order lane
- explicit `orderId` usage in [order_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/order_viewmodel.dart) status updates
- local outage and remote order merge behavior after the order-lane cutover

Manual QA is still required for:
- online cash checkout visibility in Orders
- open-ticket / pending-payment visibility
- fulfillment status change against live backend
- manual-claim outage order merge behavior in the real environment

Conclusion:
- the automated cutover regressions are closed
- the remaining work in this phase is runtime/manual verification against the live backend and staging data

---

## Success criteria

This cutover is complete when:
- Orders page is backed by `/v0/orders`
- sale history remains backed by `/v0/sales`
- fulfillment updates patch `/v0/orders/:orderId/fulfillment`
- frontend no longer confuses `saleId` with `orderId` in order actions
- sale offline-first work can continue on a correct order lifecycle

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Order vs sale consumers inventoried; id ownership locked |
| 1 | Completed | Order DTO/API seam added; fulfillment patch moved to order lane |
| 2 | Completed | Orders read lane moved to `/v0/orders` with temporary detail enrichment bridge |
| 3 | Completed | Order UI now uses explicit order identity keys; local outage orders win merge collisions |
| 4 | Completed | Backend feedback packet prepared; `fulfillmentStatus` gap closed, totals/line preview still missing |
| 5 | In progress | Automated regression coverage completed; manual QA still pending |
