# Sale KHQR Popup UX Refactor

Goal: simplify KHQR checkout interaction so QR generation happens from the cart, the popup becomes a payment-status surface, and popup actions are driven strictly by KHQR lifecycle state.

## Problem Summary

Current KHQR flow still has UX friction even after the explicit-generate fix:

1. **Duplicate generate step**
   - Cart UI asks the user to open the KHQR popup.
   - Popup then asks the user to generate KHQR again.
   - This adds an unnecessary second confirmation step.

2. **Ambiguous popup actions**
   - Popup currently mixes `Cancel KHQR` and `Close`.
   - For active KHQR attempts, `Close` can imply leaving a stale QR running without clear operator intent.

3. **Missing lifecycle helpers**
   - Popup does not yet show:
     - countdown until expiry
     - state-specific recovery action for expired KHQR
     - explicit completion action (`Done`) after payment confirmation

## Locked UX Rules

1. Cart is the **single initiation point** for KHQR generation.
2. Tapping the cart CTA must:
   - initiate KHQR immediately
   - open the popup
   - show the QR in the popup without a second generate click
3. Popup is a **status/control surface**, not a second initiation surface.
4. Popup actions are state-driven:
   - `waiting` / `pendingConfirmation`
     - `Cancel KHQR`
   - `expired`
     - `Refresh`
     - `Close`
   - `paidConfirmed`
     - `Done`
5. `Cancel KHQR` must cancel and close the popup.
6. `Cancelled` is not a visible popup end state; it returns the user to the cart.
7. Popup must show a countdown while KHQR is active and not yet expired.

## Scope

Touch only KHQR popup/cart UX:
- `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart`
- `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart`
- `lib/features/sale/ui/view/sale_cart/widgets/sale_khqr_popup.dart`
- `lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart` only if popup/cart action flow needs a small orchestration helper
- KHQR widget tests under `test/sale/`

Do not change repository contracts or unrelated sale behavior.

## Phase 0 — Lock State Model
- [x] Confirm popup-visible states vs internal states
- [x] Confirm cart CTA behavior for:
  - ready
  - superseded
  - expired
  - waiting
  - pendingConfirmation
  - paidConfirmed

Output:
- one canonical KHQR cart/popup state-action table

### Phase 0 Result

The popup/cart KHQR model is now locked as follows.

#### A. Popup-visible states

Visible popup states:
- `READY_TO_GENERATE`
  - if popup is opened manually before generation
- `WAITING_FOR_PAYMENT`
- `PENDING_CONFIRMATION`
- `EXPIRED`
- `PAID_CONFIRMED`

Internal/non-popup state:
- `CANCELLED`
  - `Cancel KHQR` should cancel and immediately close the popup
- `SUPERSEDED`
  - user should regenerate from cart, not stay in a stale popup lifecycle

#### B. Cart CTA behavior

Cart CTA is the single KHQR initiation/re-entry point:

- `READY_TO_GENERATE`
  - button intent: `Generate KHQR`
  - click behavior: initiate KHQR, then open popup with QR shown
- `SUPERSEDED`
  - button intent: regenerate latest QR
  - click behavior: initiate new KHQR, then open popup with fresh QR shown
- `EXPIRED`
  - button intent: regenerate latest QR
  - click behavior: initiate new KHQR, then open popup with fresh QR shown
- `WAITING_FOR_PAYMENT`
  - button intent: review active KHQR
  - click behavior: open popup only, no new initiate
- `PENDING_CONFIRMATION`
  - button intent: review payment status
  - click behavior: open popup only, no new initiate
- `PAID_CONFIRMED`
  - button intent: no re-entry required for generation
  - click behavior: button remains non-actionable / confirmed state only

#### C. Popup footer actions

- `WAITING_FOR_PAYMENT`
  - `Cancel KHQR`
- `PENDING_CONFIRMATION`
  - `Cancel KHQR`
- `EXPIRED`
  - `Refresh`
  - `Close`
- `PAID_CONFIRMED`
  - `Done`

#### D. Countdown rule

While KHQR is active and not expired:
- show countdown from backend `expiresAt`
- no local synthetic expiry assumptions

### Phase 0 Status

Phase 0 is complete.

## Phase 1 — Cart Becomes the Generate Trigger
- [x] Make the cart CTA initiate KHQR directly
- [x] Open popup after successful initiate
- [x] Remove the duplicate first-time generate action from popup

Output:
- first click from cart generates and shows QR immediately

### Phase 1 Result

Phase 1 is complete.

What changed:
- Cart CTA now generates KHQR directly for:
  - `READY_TO_GENERATE`
  - `SUPERSEDED`
  - `EXPIRED`
  - `CANCELLED`
- After a successful initiate, the popup opens with the active KHQR already shown.
- Popup no longer exposes first-time generation in `READY_TO_GENERATE`.
- Cart callout copy now reflects the direct-generate flow:
  - `Generate KHQR`
  - `Generate New KHQR`
  - `Review KHQR Payment`
  - `Review KHQR Status`

Regression coverage now includes:
- cart CTA generates and opens popup directly
- popup ready state no longer shows first-time generate action
- existing waiting-state review/cancel behavior remains intact

## Phase 2 — Popup Action Model
- [x] Replace static popup footer with state-driven actions
- [x] `Cancel KHQR` cancels and closes
- [x] `Expired` shows `Refresh` and `Close`
- [x] `Confirmed` shows `Done`

Output:
- popup footer is lifecycle-specific and unambiguous

### Phase 2 Result

Phase 2 is complete.

What changed:
- Popup footer is now strictly lifecycle-specific:
  - `WAITING_FOR_PAYMENT` / `PENDING_CONFIRMATION`
    - `Cancel KHQR`
  - `EXPIRED`
    - `Generate New KHQR`
    - `Close`
  - `PAID_CONFIRMED`
    - `Done`
- `Cancel KHQR` now cancels the active attempt and closes the popup immediately.
- `PAID_CONFIRMED` no longer auto-closes; operator completion is explicit through `Done`.
- Non-actionable fallback states now use a simple `Close` action instead of mixing generic close with live-payment actions.

Regression coverage now includes:
- waiting state exposes only `Cancel KHQR`
- cancel closes the popup
- expired state exposes refresh plus close
- confirmed state exposes `Done`

## Phase 3 — Countdown & Expiry UX
- [x] Show live countdown from `expiresAt`
- [x] When expired, update popup state without manual reopen
- [x] Make refresh path regenerate from popup only for expired state

Output:
- active KHQR shows urgency and expired KHQR has clear recovery

### Phase 3 Result

Phase 3 is complete.

What changed:
- Popup now runs a lightweight one-second ticker while mounted.
- Active KHQR states now show a live countdown from backend `expiresAt`:
  - `Expires in mm:ss`
- Popup derives an effective expired state from `expiresAt`, so it can switch into expired recovery UX without waiting for a manual reopen.
- Expired recovery is now popup-local:
  - `Refresh`
  - `Close`
- The expired refresh path regenerates directly from the popup only when the attempt is actually expired.

Regression coverage now includes:
- countdown renders when active `expiresAt` exists
- past `expiresAt` immediately yields expired recovery actions
- phase 2 popup action tests remain green with the countdown logic in place

## Phase 4 — Regression Tests
- [x] Add/adjust tests for:
  - cart CTA generates and opens popup directly
  - popup no longer needs a second generate step for first-time ready state
  - cancel closes popup
  - expired state shows `Refresh` + `Close`
  - confirmed state shows `Done`
  - countdown renders when `expiresAt` exists

### Phase 4 Result

Phase 4 is complete.

Regression coverage now spans the full KHQR popup/cart lifecycle:

- [test/sale/sale_cart_panel_khqr_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_cart_panel_khqr_test.dart)
  - cart CTA generates and opens popup directly
- [test/sale/sale_khqr_popup_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_khqr_popup_test.dart)
  - ready popup has no duplicate first-time generate action
  - waiting state shows countdown plus `Cancel KHQR`
  - cancel closes popup
  - expired state shows `Refresh` + `Close`
  - confirmed state shows `Done`
  - past `expiresAt` yields expired recovery UI
- [test/sale/sale_cart_content_khqr_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_cart_content_khqr_test.dart)
  - cart callout copy/buttons stay aligned with the explicit-generate model
- [test/sale/sale_cart_khqr_state_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_cart_khqr_state_test.dart)
  - state-machine regression coverage remains intact
- [test/sale/sale_khqr_smoke_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_khqr_smoke_test.dart)
  - end-to-end KHQR generate/cancel/regenerate/finalize flow remains valid

Validation run:
- `flutter test test/sale/sale_cart_khqr_state_test.dart test/sale/sale_khqr_smoke_test.dart test/sale/sale_khqr_popup_test.dart test/sale/sale_cart_panel_khqr_test.dart test/sale/sale_cart_content_khqr_test.dart test/sale/sale_cart_readonly_test.dart`

Result:
- all focused KHQR popup/cart regressions passed

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Popup/cart KHQR state-action model is now locked |
| 1 | Completed | Cart CTA now generates first and opens popup with QR already shown |
| 2 | Completed | Popup footer now changes by KHQR lifecycle state |
| 3 | Completed | Countdown and expiry-derived popup recovery are now in place |
| 4 | Completed | KHQR popup/cart regression suite now covers the revised lifecycle flow |
