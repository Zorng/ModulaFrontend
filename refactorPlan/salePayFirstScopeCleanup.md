# Sale Pay-First Scope Cleanup

Status: In progress  
Owner context: Frontend POS / Sale-Order UI

## Goal

Correct the current sale UI back to the intended increment:

- online pay-first cash
- online pay-first KHQR
- fulfillment continuity after payment

This cleanup exists because exploratory work for:

- pay-later management
- manual-claim review
- outage claim workflow

was surfaced in the current sale UI even though those are not part of the
current pay-first release target.

---

## Scope lock

### In scope

- keep direct-checkout fulfillment visible
- keep order-backed fulfillment status updates
- remove `Pay Later` and `Manual Claims` from the current sale workspace UI
- restore clear fulfillment-first naming in the sale shell

### Out of scope

- deleting the underlying order/open-ticket/manual-claim architecture
- deleting outage/offline code paths already implemented
- implementing offline cash replay
- implementing outage external-payment-claim UX for release

Important rule:

- this is a release-scope cleanup, not a rollback of the order-based backend cutover

---

## Phase 0 — Scope Correction Lock
- [x] Lock the release correction:
  - current sale UI focuses on direct-checkout fulfillment only
- [x] Park pay-later/manual-claim workspace UI for a later increment

Output:

- cleanup target is explicit

---

## Phase 1 — Fulfillment-Only Workspace
- [x] Remove top-level `Pay Later` and `Manual Claims` tabs from the current order workspace
- [x] Restore a single fulfillment-first surface
- [x] Keep fulfillment status filtering and status updates

Output:

- current sale order screen is fulfillment-only again

---

## Phase 2 — Naming Cleanup
- [x] Rename the current sale shell tab back to `Fulfillment`
- [x] Remove stale queue-selection state that only existed for the extra tabs

Output:

- sale navigation matches the corrected increment

---

## Phase 3 — Validation
- [x] Update order page regression tests
- [x] Run focused analyze/test for touched sale order files

Output:

- cleanup is verified

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 Scope Correction Lock | Completed | Current sale release is pay-first + fulfillment only. |
| 1 Fulfillment-Only Workspace | Completed | Extra order workspace tabs removed from current UI. |
| 2 Naming Cleanup | Completed | Sale shell tab restored to `Fulfillment`. |
| 3 Validation | Completed | Focused analyze/test green on the cleanup slice. |

---

## Related note

The broader work captured in [saleOrderUiTabRefactor.md](/Users/mac/flutterProjects/modular/refactorPlan/saleOrderUiTabRefactor.md)
is now effectively parked for a later increment. The architectural findings are still useful,
but its UI rollout is not the current release target.
