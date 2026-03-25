# Sale Void Workflow UI

Goal: introduce a real sale-detail workflow surface for finalized and void-related sales, so void request / approve / reject actions live in the correct business UI and the stale cart-level direct-void behavior is removed.

## Why This Exists

The repo currently has a gap between backend contract, product rules, and frontend UI.

What the backend contract already supports:
- cashier can request void on an eligible finalized sale
- manager/admin can approve or reject a pending void request
- approval executes the sale void and reverses downstream effects

What the frontend currently has:
- a simple `Void Sale` action on carts only when `state == PENDING`
- cart/detail summary pages that can display `VOID_PENDING` / `VOIDED` badges
- no real finalized-sale void workflow page

Why that is wrong:
- carts are local and should be discarded/deleted, not voided
- void applies only to finalized sales
- so the current cart-level `Void Sale` behavior is legacy drift that must be removed

That mismatch is now also blocking notification routing.

## Current State

### Existing frontend surfaces

- `ViewCartsPage`
  - lists sales by status
  - currently still carries the stale direct-cart-void behavior
  - currently acts as the temporary destination for void notifications
- `ViewCartDetailPage`
  - summary UI only
  - usually opened as a modal
  - does not fetch by `saleId`
  - does not expose request/approve/reject workflow
- `OrderDetailPage`
  - focused on fulfillment + manual payment claim review
  - not the right semantic owner for sale void workflow

### Existing void behavior

- `SaleSummary.canVoid` currently only returns true for `PENDING`
- carts can call `voidSale(...)` directly
- that current behavior is not the intended product model and should be removed
- there is no frontend UI yet for:
  - request void on `FINALIZED`
  - review pending void request
  - approve void
  - reject void

### Existing backend contract

Available in `integration/sale-order-v0.md`:
- `POST /v0/sales/:saleId/void/request`
- `POST /v0/sales/:saleId/void/approve`
- `POST /v0/sales/:saleId/void/reject`
- `POST /v0/sales/:saleId/void/execute`
- `GET /v0/sales/:saleId`
- `GET /v0/sales/:saleId/void-request`

Backend contract is the source of truth for this tracker.
Do not preserve cart-level direct void just because it exists in the current frontend.

## Phase 0 Findings

### Surface inventory

- `ViewCartsPage`
  - list surface for `PENDING`, `FINALIZED`, `VOID_PENDING`, and `VOIDED`
  - opens `ViewCartDetailPage` as a responsive modal
  - still owns the direct void confirm flow via `_voidSale(...)`
- `ViewCartDetailPage`
  - read-only summary modal for the selected `SaleSummary`
  - can still render a destructive `Void Sale` action through `onVoid`
  - only shows informational notices for `VOID_PENDING` and `VOIDED`
- `OrderDetailPage`
  - order/fulfillment and manual external-payment-claim surface
  - not semantically aligned to sale-void review

### Stale void behavior that must be removed

- `SaleSummary.canVoid` currently returns true only when `state == PENDING`
- `ViewCartsPage._voidSale(...)` still shows a direct confirm dialog and calls `repo.voidSale(...)`
- `SaleSummaryCard` and `ViewCartDetailPage` still expose a `Void Sale` button when `onVoid != null`
- `test/sale/view_carts_ui_test.dart` currently locks the presence of that cart-level `Void Sale` behavior

### Routing and data-layer gaps

- `saleViewCartDetail` currently depends on `state.extra as SaleSummary`
  - this prevents a fetch-by-`saleId` detail page
  - notifications cannot use it as a canonical business destination
- `operational_notification_navigation.dart` still routes void notifications to filtered carts, not to a real sale-void detail workflow
- `SaleCheckoutRepository` / `SaleApi` still expose a legacy `voidSale(...)` command mapped to `POST /v0/sales/:saleId/void`
  - current frontend does not yet expose:
    - `void/request`
    - `void/approve`
    - `void/reject`
    - `GET /sales/:saleId/void-request`

### Backend contract requirements the new UI must satisfy

- carts remain local and are discarded/deleted, not voided
- void workflow applies only to finalized sales
- frontend needs an authoritative sale-detail flow built around:
  - `GET /v0/sales/:saleId`
  - `GET /v0/sales/:saleId/void-request`
  - `POST /v0/sales/:saleId/void/request`
  - `POST /v0/sales/:saleId/void/approve`
  - `POST /v0/sales/:saleId/void/reject`
- notification handoff should eventually land in that sale-detail flow instead of the carts list

## Locked Product / Architecture Direction

### 1) Draft carts are not voided

Do:
- treat draft/cart removal as local discard/delete behavior

Do not:
- model cart deletion as sale void
- preserve cart-level `Void Sale` as an interim workflow

### 2) The real target is a sale-detail workflow page

Do:
- build a dedicated sale detail surface that fetches by `saleId`
- let it own void request / approve / reject behavior

Do not:
- use order cancellation UI as a substitute
- keep void workflow trapped inside notification-only surfaces
- keep relying on carts as the final destination for actionable void notifications

### 3) Existing business pages remain the source of truth

- notification payload must not be the source of truth
- the sale page must refetch sale detail from backend
- void request detail must be refetched from backend
- current auth/business rules remain authoritative

### 4) The workflow is role-based

Cashier:
- can request void on eligible finalized sale

Manager/Admin/Owner:
- can review a pending void request
- can approve or reject

### 5) Notification routing should eventually target this page

Once this UI exists:
- `VOID_APPROVAL_NEEDED`
- `VOID_APPROVED`
- `VOID_REJECTED`

should resolve into this sale detail / void workflow surface, not the carts list.

## Proposed Surface Shape

## Page responsibility

One page should show:
- sale summary
- current sale state
- payment method / totals / timestamps
- fulfillment snapshot
- void request section when present
- role-aware actions

## Role-aware action behavior

### Cashier on eligible `FINALIZED` sale
- show `Request void`
- open reason dialog
- submit `void/request`
- refresh page

### Manager/Admin/Owner on `VOID_PENDING`
- show void request detail
  - requested by
  - requested at
  - reason
- show:
  - `Approve void`
  - `Reject void`
- collect optional/required review note as needed
- refresh page after action

### On `VOIDED`
- read-only state
- show void metadata

### On ineligible sales
- no destructive action
- explain why if needed in a later pass

## Routing Direction

Current problem:
- `saleViewCartDetail` depends on `state.extra`
- notifications do not have a `SaleSummary`

Target direction:
- add or repurpose a sale detail route that accepts `saleId` in the path/query
- page fetches detail by id
- notifications and normal in-app navigation can both use it

## Data-Layer Implications

Frontend likely needs:
- sale detail read model mapped from `GET /v0/sales/:saleId`
- void request detail read model mapped from `GET /v0/sales/:saleId/void-request`
- commands for:
  - request void
  - approve void
  - reject void

This tracker does not yet assume the final exact file split, only the workflow direction.

## Phase 2 Decisions

### Canonical workflow route

- the authoritative void workflow route should be sale-keyed, not cart-keyed
- do not repurpose `saleViewCartDetail` as the final business destination
  - it depends on `state.extra`
  - it is modal/summary oriented
  - it is not suitable for notification or fulfillment deep-link entry
- target direction:
  - add a dedicated sale detail route keyed by `saleId`
  - use that route for:
    - normal in-app review of finalized sales
    - notification handoff
    - fulfillment-entry handoff

### Fulfillment as entry surface, not source of truth

- the kitchen/fulfillment board is allowed to be the operational entry surface for void workflow
- but it must not become the data owner for sale void
- the fulfillment board should open the sale-keyed workflow route
- it should not host approve/reject state itself

### No extra discovery hop rule

- if fulfillment is used as the entry surface, the order summary must carry `saleId`
- do not require:
  - fulfillment list -> order detail -> discover `saleId` -> sale detail
- the current frontend violates this:
  - `Order` already has `saleId`
  - `SaleOrderSummaryDto` already has `saleId`
  - but `SaleRepository.getOrders(...)` currently maps listed orders to `saleId: ''`
- phase 2 therefore locks this requirement:
  - preserve or add `saleId` on fulfillment list rows so the board can deep-link directly to the sale workflow

### Keep the order list lean

- do not duplicate full sale detail into the fulfillment list payload
- order list should remain a lightweight operational board read model
- minimum useful cross-link fields for void entry are:
  - `saleId`
- useful optional additions if available cheaply:
  - `saleStatus`
  - `voidRequestStatus`
- authoritative financial/void detail is still fetched on demand from sale endpoints

### Repository / API direction

- remove reliance on the legacy `voidSale(...)` command for the new workflow
- extend the sale-facing repository surface around:
  - `getSaleDetail(saleId)`
  - `getSaleVoidRequest(saleId)`
  - `requestSaleVoid(saleId, reason)`
  - `approveSaleVoid(saleId, reviewNote?)`
  - `rejectSaleVoid(saleId, reviewNote?)`
- `execute` remains backend workflow territory and should not be assumed as a first-pass cashier/manager UI action

### Legacy route coexistence

- keep the existing cart detail route only as a temporary quick-view surface while carts still exist in current UI
- do not point notifications or fulfillment actions to that route
- the new sale-keyed route becomes the business-workflow destination

## Non-Goals

This tracker does not cover:
- notification scope/account bell behavior
- notification modal design
- order fulfillment cancellation UI
- local cart discard/delete UX beyond the boundary that it is not void
- refund workflow
- reopening sales

## Phase Plan

## Phase 0 — Inventory Current Sale Void Surfaces
- [x] list all current sale detail / carts / order detail surfaces
- [x] record what void-related behavior already exists
- [x] record which current cart-level void assumptions must be removed
- [x] record backend endpoints and rules the new UI must satisfy

Output:
- one inventory of current seams and gaps

## Phase 1 — Lock UX Contract
- [ ] define the target sale detail page responsibilities
- [ ] define role-aware actions by sale state
- [ ] define when the page is modal vs full-page
- [ ] lock that notifications will eventually deep-link here

Output:
- stable sale void workflow UI contract

## Phase 2 — Data Model And Route Shape
- [x] decide route shape for sale detail by `saleId`
- [x] define frontend models/repository methods for sale detail + void request detail
- [x] decide whether current cart detail route is replaced or complemented
- [x] define where legacy direct-cart-void logic is removed from the current carts flow

Output:
- implementation-ready route/data plan

## Phase 3 — Read-Only Sale Detail Foundation
- [x] build the fetch-by-id sale detail page
- [x] show sale summary + current state + fulfillment snapshot
- [x] show void request detail when present
- [x] add tests for loading / empty / error / state rendering

Output:
- authoritative sale detail page exists

## Phase 4 — Cashier Void Request Flow
- [x] add `Request void` for eligible finalized sales
- [x] collect reason
- [x] submit command
- [x] refresh and show `VOID_PENDING`
- [x] add tests

Output:
- cashier request flow works

## Phase 5 — Manager/Admin Review Flow
- [ ] add approve / reject actions for `VOID_PENDING`
- [ ] collect review note as needed
- [ ] refresh to `VOIDED` or restored `FINALIZED`
- [ ] add tests

Output:
- review flow works

## Phase 6 — Notification Integration Follow-Through
- [ ] repoint void notifications from carts to the new sale detail page
- [ ] keep explicit tenant/branch handoff
- [ ] add regression tests for notification deep-link into sale void workflow

Output:
- notifications land in the correct business UI

## Phase 7 — Validation
- [ ] `flutter analyze`
- [ ] targeted `flutter test`
- [ ] manual QA across:
  - cashier request flow
  - manager/admin approve flow
  - reject flow
  - notification entry
  - cross-tenant/branch handoff

Output:
- validated sale void workflow UI

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Current frontend still has stale cart-level direct void in UI, route expectations, repository/API, notification routing, and tests. |
| 1 | Not started |  |
| 2 | Completed | Canonical workflow route is sale-keyed; fulfillment can be the entry surface only if order summaries preserve `saleId` and do not require an order-detail discovery hop. |
| 3 | Completed | Read-only sale detail page now exists as a sale-keyed route with sale + void-request reads and focused page tests. |
| 4 | Completed | Cashier can request void from sale detail, submit a reason through `void/request`, and the page refreshes into `VOID_PENDING` with focused page/repository/widget coverage. |
| 5 | Not started |  |
| 6 | Not started |  |
| 7 | Not started |  |
