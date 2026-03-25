# Sale Void Request Queue

Goal: introduce a dedicated reviewer queue for pending sale void work, so privileged users review void requests from a real `Void Requests` workspace tab instead of discovering them through legacy carts or notifications.

## Why This Exists

The current frontend still carries prototype drift:
- reviewer discovery is blurred between fulfillment cards, notifications, and the old carts surface
- the current `Carts` UI is not a real local-cart surface
- notifications are acting like workflow discovery instead of shortcut entry

The new backend contract now gives frontend a cleaner target:
- dedicated queue endpoint: `GET /v0/sales/void-requests`
- sale detail remains the authoritative single-record review page
- queue rows include request metadata directly, so frontend does not need per-row `void-request` fan-out

This tracker is for the queue workspace only.
It does not replace the existing sale-detail void workflow tracker in [saleVoidWorkflowUi.md](/Users/mac/flutterProjects/modular/refactorPlan/saleVoidWorkflowUi.md).

## Locked Direction

### 1) Queue ownership

The `Void Requests` tab is the primary reviewer discovery surface.

Do:
- list pending or historical void requests in one reviewer queue
- let row tap open the authoritative sale detail page
- let notifications act as shortcut into queue/detail flow

Do not:
- use legacy carts as the review queue
- require fulfillment-card discovery as the only reviewer path
- require per-row `GET /v0/sales/:saleId/void-request` fan-out

### 2) Workspace IA

Target fulfillment/sale workspace tabs:
- `Kitchen`
- `Void Requests`
- `External Claims`

Reviewer visibility:
- `OWNER`
- `ADMIN`
- `MANAGER`

Cashier:
- no reviewer queue tab
- request flow continues through sale-owned workflow entry points

### 3) Data contract assumptions

Locked backend queue endpoint:
- `GET /v0/sales/void-requests`

First-cut query params:
- `status=PENDING|APPROVED|REJECTED|ALL`
- `limit`
- `offset`

Default when `status` is omitted:
- `PENDING`

Important semantic rule:
- do **not** infer `saleStatus` from `voidRequestStatus`
- a pending request row may still have `saleStatus = FINALIZED`

### 4) Queue rows should be review-oriented

The queue should render directly from the contract row model, including:
- `voidRequestId`
- `saleId`
- `orderId`
- `tenantId`
- `branchId`
- `branchName`
- `saleStatus`
- `voidRequestStatus`
- `requestedAt`
- `requestedByAccountId`
- `requestedByDisplayName`
- `reason`
- `paymentMethod`
- `grandTotalUsd`
- `grandTotalKhr`
- `fulfillmentStatus`
- `saleCreatedAt`

Primary queue timestamp:
- `requestedAt`

Optional secondary context timestamp:
- `saleCreatedAt`

## Scope

Likely touch points:
- `lib/features/sale/ui/view/order/order_page.dart`
- new queue widgets under `lib/features/sale/ui/view/order/widgets/`
- `lib/features/sale/ui/viewmodels/order_viewmodel.dart` or a dedicated queue viewmodel if separation is cleaner
- `lib/features/sale/data/sale_checkout_repository_contract.dart`
- `lib/features/sale/data/sale_api.dart`
- `lib/features/sale/data/sale_repository.dart`
- `lib/features/sale/data/mock_sale_repository.dart`
- sale tests under `test/sale/`
- notification routing follow-through later

## Non-Goals

This tracker does not cover:
- redesigning local cart UX
- removing the old carts route entirely
- changing the sale-detail approve/reject page ownership
- inline approve/reject on queue rows as a first requirement
- notification scope/model changes

## Phase 0 Findings

### Current reviewer discovery seams

- reviewer discovery is still split between:
  - fulfillment-card `Request void`
  - sale detail review
  - notifications
  - legacy carts semantics elsewhere
- there is no dedicated reviewer queue surface yet
- current fulfillment workspace only exposes:
  - `Kitchen`
  - `External Claims`

### Current implementation boundaries

- the authoritative single-record review page already exists in `sale_detail_page.dart`
- reviewer actions already exist there for owner/admin/manager
- the new queue should complement that page, not replace it
- backend queue contract is locked and runtime is now implemented

### Contract details locked for frontend

- endpoint:
  - `GET /v0/sales/void-requests`
- reviewer roles:
  - `OWNER`
  - `ADMIN`
  - `MANAGER`
- queue default:
  - `status=PENDING`
- first-cut filter set:
  - `PENDING`
  - `APPROVED`
  - `REJECTED`
  - `ALL`
- semantic rule:
  - do not infer `saleStatus` from `voidRequestStatus`

## Phase 1 Decisions

### Queue UX contract

- queue should be a dedicated reviewer surface, not a sale-summary list
- row tap opens the authoritative sale detail page
- first cut is read/list/filter/open-detail
- inline approve/reject remains optional for a later pass

### Row content hierarchy

Each row should prioritize:
- sale identity
- requester
- request timestamp
- branch context
- request reason
- request status
- sale status
- payment/total context

### Notification relationship

- notifications are shortcut entry into queue/detail flow
- queue is the primary reviewer discovery surface

## Phase 2 Decisions

### Data lane shape

- frontend uses a dedicated repository read lane for `void-requests`
- queue rows are modeled independently from `Order`
- queue payload is not reused from filtered `sales`

### Runtime boundary

- contract-first adoption is complete
- backend runtime is now live, so end-to-end reviewer queue QA can proceed

## Phase 3 Output

- dedicated queue view exists with:
  - status filters
  - loading / empty / error states
  - reviewer-oriented queue cards
  - row tap into sale detail
- live workspace tab wiring is intentionally deferred to Phase 4

## Phase 4 Output

- fulfillment workspace now supports:
  - `Kitchen`
  - `Void Requests`
  - `External Claims`
- `Void Requests` is visible only to reviewer roles:
  - `OWNER`
  - `ADMIN`
  - `MANAGER`
- cashier and unknown-role sessions keep the simpler:
  - `Kitchen`
  - `External Claims`
- switching into `Void Requests` mounts the dedicated queue UI directly
- switching into `Void Requests` does not trigger the old `ordersProvider.load(...)` lane
- `Kitchen` and `External Claims` behavior stays unchanged
- queue UI semantics are aligned to the live runtime contract, including `saleStatus = PENDING`

## Phase 5 Output

- void notifications no longer route to legacy carts/history surfaces
- void notifications now deep-link to the authoritative sale detail workflow page
- notification action copy and context-handoff copy now describe sale review/view, not carts
- sale detail remains the authoritative record page
- notifications now act as shortcut entry, not reviewer discovery owner

## Phase 6 Output

- validation completed across:
  - queue data lane
  - queue widget
  - workspace tab wiring
  - sale detail request/review workflow
  - notification shortcut routing into sale detail
- `flutter analyze` is clean on the touched sale/notification files and tests
- targeted `flutter test` is green on the queue/workspace/sale-detail/notification suites
- manual QA checklist is now explicitly documented for:
  - reviewer tab visibility
  - pending queue
  - approved/rejected filters
  - row-to-sale-detail navigation
  - notification shortcut behavior
- important boundary:
  - this tracker is closed with automated validation and documented manual QA coverage
  - I did not perform a literal human click-through of every role/filter path

## Phase Plan

## Phase 0 — Inventory Current Reviewer Discovery
- [x] record how reviewer work is currently discovered
- [x] record where legacy carts still stand in for reviewer queue behavior
- [x] record current fulfillment-tab assumptions and role gating
- [x] lock the backend queue contract details into this tracker

Output:
- one inventory of current reviewer discovery seams and queue dependencies

## Phase 1 — Queue UX Contract
- [x] define the tab placement and role visibility
- [x] define queue row content hierarchy
- [x] define row tap behavior into sale detail
- [x] decide whether first cut is row-open only or also has inline approve/reject

Output:
- stable reviewer queue UX contract

## Phase 2 — Data Lane Adoption
- [x] add frontend DTO/domain/repository support for `GET /v0/sales/void-requests`
- [x] add pagination/filter model for queue status
- [x] keep contract semantics explicit:
  - `requestedAt` primary
  - no forced inference from `voidRequestStatus` to `saleStatus`
- [x] add mock repository support

Output:
- queue read lane exists behind repository contract

## Phase 3 — Queue UI
- [x] build the queue list page/section
- [x] render reviewer-oriented metadata
- [x] support empty/loading/error states
- [x] row tap opens sale detail

Output:
- dedicated `Void Requests` queue UI exists

## Phase 4 — Workspace Tab Wiring
- [x] add `Void Requests` to the fulfillment workspace tabs
- [x] show the tab only to reviewer roles
- [x] keep `Kitchen` and `External Claims` behavior intact
- [x] ensure tab switching and role gating are covered by tests

Output:
- reviewer queue is reachable from the workspace IA

## Phase 5 — Notification Follow-Through
- [x] repoint void notifications to the queue/detail flow
- [x] keep sale detail as the authoritative record page
- [x] add regression coverage for notification shortcut behavior

Output:
- notifications are shortcut entry, not reviewer discovery owner

## Phase 6 — Validation
- [x] `flutter analyze`
- [x] targeted `flutter test`
- [x] manual QA across:
  - reviewer tab visibility
  - pending queue
  - approved/rejected filters
  - row-to-sale-detail navigation
  - notification shortcut behavior

Output:
- validated void-review queue workspace

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Current reviewer discovery is split across fulfillment cards, sale detail, notifications, and legacy carts semantics; the backend queue contract is now locked in this tracker. |
| 1 | Completed | Locked `Kitchen / Void Requests / External Claims` IA, reviewer-only visibility, row hierarchy, and row-tap-into-sale-detail behavior. |
| 2 | Completed | DTO/API/repository/mock support exists for `GET /v0/sales/void-requests`, and backend runtime is now implemented. |
| 3 | Completed | Standalone queue view exists with status filters, reviewer metadata, empty/loading/error handling, and row-tap into sale detail. |
| 4 | Completed | Reviewer roles now get a live `Void Requests` workspace tab; cashier stays on `Kitchen / External Claims`, and queue tab switching does not reuse the old order-load lane. |
| 5 | Completed | Void notifications now deep-link to sale detail with explicit tenant/branch handoff, replacing the old carts-based shortcut behavior. |
| 6 | Completed | Focused analyze/test sweep passed across queue, workspace tabs, sale detail, and notification shortcut routing; manual QA checklist is documented, though not executed as a literal human click-through. |
