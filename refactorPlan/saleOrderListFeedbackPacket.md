# Sale Order List Feedback Packet

Context:
- frontend Orders list is now on `GET /v0/orders`
- frontend no longer needs per-row `GET /v0/orders/:orderId` enrichment for the basic card surface
- this feedback packet is now only about the remaining contract gaps

Source of truth:
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)

## Current backend list payload

Current list example now includes:
- `id`
- `status`
- `sourceMode`
- `fulfillmentStatus`
- `totalUsdExact`
- `linesPreview`
- `checkedOutAt`
- `paymentMethod`
- `manualPaymentClaimId`
- `manualPaymentClaimStatus`
- `createdAt`
- `updatedAt`

This is now enough for the current frontend Orders list surface:
- order identity
- open vs checked-out classification
- fulfillment badge state
- USD total
- lightweight line preview
- checked-out/payment-method state
- manual-claim summary state

## Remaining missing fields

These are the only backend gaps still relevant to the current frontend.

### 1. `saleType`
- current Orders surfaces still have to fake order type labels (`dine_in` / `take_away`)
- this is not blocking the list cutover anymore, but it is still not authoritative

### 2. `totalKhrExact`
- frontend currently derives KHR total from current branch policy
- this is acceptable as a temporary fallback
- but it is not authoritative order-list truth

## Can still be derived client-side

These do not need backend changes.

1. `ticketStatus`
- frontend derives:
  - `OPEN -> UNPAID`
  - otherwise `PAID` unless cancelled

2. status chip label/color
- frontend derives from:
  - `fulfillmentStatus`
  - fallback `status`

3. order identity key
- frontend derives from `orderId`

4. open-ticket semantics
- frontend derives from `status == OPEN`

## Updated recommendation to backend

If backend wants the order-list contract to be fully authoritative for the current frontend, the remaining useful additions are:

```json
{
  "id": "uuid",
  "status": "OPEN",
  "sourceMode": "STANDARD",
  "fulfillmentStatus": "PREPARING",
  "saleType": "DINE_IN",
  "totalUsdExact": 3.5,
  "totalKhrExact": 14350,
  "linesPreview": [
    {
      "menuItemNameSnapshot": "Iced Latte",
      "quantity": 1,
      "modifierLabels": ["Less ice"]
    }
  ],
  "checkedOutAt": null,
  "paymentMethod": null,
  "manualPaymentClaimId": null,
  "manualPaymentClaimStatus": null,
  "createdAt": "2026-02-22T10:00:00.000Z",
  "updatedAt": "2026-02-22T10:03:00.000Z"
}
```

## Practical status

What frontend no longer needs:
- per-row detail fan-out for Orders cards

What frontend still keeps as fallback:
- client-derived `totalKhrExact`
- placeholder/fallback `orderType` until `saleType` is exposed authoritatively
