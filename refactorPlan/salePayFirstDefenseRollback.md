# Sale Pay-First Defense Rollback

Status: In progress  
Owner context: Frontend POS / Sale / Policy / Fulfillment

## Goal

Lock the final Capstone II frontend scope back to a clean pay-first release:

- direct payment checkout only
- post-payment fulfillment only
- no active pay-later / open-order user path
- no misleading UI or report wording that implies current support

This rollback exists because the current frontend still exposes parts of the
older order/open-ticket model even though pay-later/open-order is now treated
as deferred future work for the academic report and final defense.

---

## Scope Lock

### Final supported frontend scope

- pay-first cash checkout
- pay-first KHQR checkout
- post-payment fulfillment
- void request / review on finalized sale surfaces

### Not in final supported frontend scope

- pay-later / open-order placement
- open-ticket settlement from active UI
- branch policy editing for pay-later enablement
- screenshots or report wording that imply pay-later is active

### Important boundary

This is a defense-scope rollback, not a full deletion of all order-lane code.

Dormant repository/API/model structure may remain for future work, but it must
be unreachable from the active frontend and must not be described as currently
supported.

Backend contract confirmation:
- the updated `sale-order` contract now treats open-order/pay-later and manual external-payment-claim flows as removed from the active final scope
- the active final checkout lane is pay-first only

---

## Current Active Drift

The current repo still has live pay-later/open-order exposure in these places:

1. Cart flow
- [sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart)
  - `dine_in` still triggers pay-later mode
  - primary CTA still becomes `Place Order`
  - open-ticket success feedback still appears
  - `View Ticket` still opens an `Open Ticket` dialog
- [sale_order_type_selector.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_order_type_selector.dart)
  - `Dine in` is still exposed in the current order-type selector even though it is tied to the pay-later branch

2. Policy UI
- [policy_page.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/view/policy/policy_page.dart)
  - still shows `Allow Pay Later`
  - still describes placing open tickets before payment

3. Order detail
- [order_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order_detail/order_detail_page.dart)
  - still shows `Open Ticket Settlement`
  - still exposes direct collection / settlement actions for unpaid tickets

4. Fulfillment wording
- [order_card.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/widgets/order_card.dart)
  - still describes a pay-later ticket awaiting settlement

5. Defense-scope adjacency to verify
- [order_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/order/order_page.dart)
  - current `External Claims` workspace is also not part of a strict pay-first defense scope and should be reviewed during this rollback

---

## Rollback Rules

### Fully remove from active UI

- pay-later cart placement path
- `Place Order` CTA for open-ticket creation
- open-ticket success banner and `View Ticket`
- `Open Ticket` dialog entry
- `Allow Pay Later` policy control
- `Open Ticket Settlement` section and settlement buttons
- pay-later wording on fulfillment/order cards

### Leave in code but unreachable

- order/open-ticket repository and API methods
- policy model fields such as `saleAllowPayLater`
- order-lane model flags such as unpaid/open-ticket state
- mock/test scaffolding that preserves future order-lane work

### Optional internal flag only if needed

If engineering needs a non-default internal recovery switch, it must be hidden
behind a non-release flag and must stay off for staging and defense builds.

Preferred outcome:
- no visible flag-driven pay-later UX in the final staged frontend

---

## Docs And Report Rules

### Must update or avoid in final report material

- screenshots showing `Place Order`
- screenshots showing `View Ticket`
- screenshots showing `Allow Pay Later`
- screenshots showing `Open Ticket Settlement`
- any wording that describes open-ticket placement as an active user flow

### Treat as broader contract or historical engineering material

- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)
- [policy-v0.md](/Users/mac/flutterProjects/modular/integration/policy-v0.md)
- [media-v0.md](/Users/mac/flutterProjects/modular/integration/media-v0.md)
- older refactor plans involving pay-later/open-ticket exploration

These may still describe architecture or deferred work, but they must not be
used as evidence of final active frontend scope.

---

## Report-Safe Wording

### Final scope paragraph

`The final Capstone II frontend scope was narrowed to a pay-first operational model. In the staged UI, the active user flow supports direct payment checkout and post-payment fulfillment only, while pay-later/open-order behavior was removed from user-reachable paths because it was not validated robustly across both online and offline conditions within the project timeline.`

### Dormant future-work wording

`Some underlying order-lane scaffolding remains in the codebase for future extension, but it is not exposed in the active frontend and should not be described as a supported Capstone II feature.`

---

## Phase Plan

## Phase 0 — Scope Lock And Audit
- [x] Confirm final defense narrative is pay-first only
- [x] Inventory active pay-later/open-order UI drift
- [x] Lock which items are UI-removal targets versus dormant structure

Output:
- rollback boundary is explicit and report-safe

## Phase 1 — Remove Active Pay-Later Entry Points
- [x] Remove pay-later placement from cart UI
- [x] Remove open-ticket success feedback and ticket dialog
- [x] Remove or rebind order-type selection so it does not imply pay-later placement

Output:
- no active cart path can create an unpaid/open ticket

## Phase 2 — Remove Policy And Settlement Exposure
- [x] Remove `Allow Pay Later` from active policy UI
- [x] Remove `Open Ticket Settlement` from order detail
- [x] Remove pay-later helper copy from fulfillment/order cards

Output:
- no active policy or order-detail surface implies current pay-later support

## Phase 3 — Defense-Scope Adjacency Cleanup
- [x] Review `External Claims` and other non-pay-first workspace lanes
- [x] Decide whether those lanes must also be hidden for final defense scope
- [x] Ensure inactive order-lane code remains unreachable, not half-exposed

Output:
- active staging UI reads as pay-first only

## Phase 4 — Docs, Screenshots, And Validation
- [ ] Refresh report-facing screenshots
- [x] Ensure final report wording matches staged UI
- [x] Update or annotate any defense-facing docs if needed
- [x] Run focused analyze/test on touched frontend areas

Output:
- implementation, screenshots, and report tell the same story

Note:
- in-repo wording/tracker cleanup is complete
- screenshot recapture for the academic report is still a manual human task outside this repo

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 Scope Lock And Audit | Completed | Active pay-later drift confirmed in cart, policy, order detail, and fulfillment wording. |
| 1 Remove Active Pay-Later Entry Points | Completed | Cart no longer exposes open-ticket placement or ticket follow-up actions. |
| 2 Remove Policy And Settlement Exposure | Completed | Pay-later policy toggle removed; legacy open-ticket settlement is hidden from order detail. |
| 3 Defense-Scope Adjacency Cleanup | Completed | `External Claims` is no longer an active workspace tab; deferred claim UI is gated off. |
| 4 Docs, Screenshots, And Validation | Completed | Focused analyze/tests are green; report screenshot recapture is a manual follow-up outside the repo. |
