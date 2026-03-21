# Sale Quick Cash Checkout Backend Feedback

Issue date: 2026-03-19

## Summary

Quick cash checkout is currently failing on staging with HTTP `500` from:

- `POST /v0/checkout/cash/finalize`

Backend response:

```json
{
  "success": false,
  "error": "new row for relation \"v0_order_tickets\" violates check constraint \"v0_order_tickets_source_mode_check\""
}
```

## Frontend assessment

This looks like a backend order-anchor materialization issue, not a frontend request-shape issue.

Why:

- Frontend quick cash checkout correctly uses:
  - `POST /v0/checkout/cash/finalize`
- Frontend payload does **not** send `sourceMode`
- Per the current contract, backend should materialize the checked-out order with:
  - `sourceMode = DIRECT_CHECKOUT`

Relevant frontend code:

- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
- [sale_api.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_api.dart)

## What frontend sends

Quick cash checkout currently sends only:

```json
{
  "items": [
    {
      "menuItemId": "uuid",
      "quantity": 1,
      "modifiers": []
    }
  ],
  "saleType": "TAKEAWAY",
  "tenderCurrency": "USD",
  "cashReceivedTenderAmount": 10
}
```

Important:

- frontend does **not** send `sourceMode`
- frontend expects backend to create:
  - finalized sale
  - checked-out order anchor

## Contract expectation

From the current remodel contract:

- quick cash checkout is no longer sale-only
- backend should atomically create:
  - `FINALIZED sale`
  - `CHECKED_OUT order`
- that order should be fulfillable afterward
- the order anchor should be a direct checkout order

Expected backend-internal order value:

- `sourceMode = DIRECT_CHECKOUT`

## Most likely backend causes

One of these is likely true on staging:

1. The DB constraint was not migrated to allow `DIRECT_CHECKOUT`.
2. Backend code is writing a source-mode value that does not exactly match the constraint.
3. Staging backend code and staging schema are on different revisions.

## Backend checks requested

Please verify:

1. `v0_order_tickets_source_mode_check` includes:
   - `STANDARD`
   - `MANUAL_EXTERNAL_PAYMENT_CLAIM`
   - `DIRECT_CHECKOUT`

2. The quick-cash finalize flow inserts:
   - `sourceMode = DIRECT_CHECKOUT`

3. Staging has the latest migration applied for the remodeled order-ticket source-mode enum/check.

## Reproduction

1. Open sale cart online.
2. Add one item.
3. Choose cash payment.
4. Run checkout.
5. Observe backend `500` from `POST /v0/checkout/cash/finalize`.

## Frontend status

Frontend quick cash path is already aligned to the new contract and does not appear to need a request-shape change for this issue.
