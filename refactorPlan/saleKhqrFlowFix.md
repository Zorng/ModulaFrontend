# Sale KHQR Flow Fix

Goal: correct KHQR generation behavior in the sale cart flow so it matches explicit operator intent and branch prerequisites.

## Problem Summary

Current KHQR behavior has two UX/runtime defects:

1. **Missing receiver prevention**
   - KHQR generation requires the branch KHQR receiver to be configured.
   - Frontend currently sends the KHQR initiate request even when the receiver is missing.
   - Backend rejects it correctly, but the UI should prevent the request before network.

2. **Auto-generation on cart mutation**
   - KHQR initiation is currently triggered automatically from cart/viewmodel state transitions.
   - Adding items, changing quantities, or changing cart state can initiate/supersede KHQR implicitly.
   - KHQR generation should be **on-demand only**.

## Locked UX Rules

1. Selecting `QR` as payment method must **not** initiate KHQR.
2. Adding/removing/updating cart items must **not** initiate KHQR.
3. KHQR may be initiated only from an explicit user action:
   - `Generate QR`
   - or opening the KHQR popup if that action is explicitly treated as generation
4. If cart/payment inputs change after a KHQR has already been generated:
   - current KHQR becomes `superseded`
   - frontend must require explicit regeneration
   - frontend must not auto-regenerate
5. If branch KHQR receiver is not configured:
   - frontend must block KHQR generation before network
   - UI should explain why KHQR is unavailable

## Scope

Touch only KHQR-related sale flow:
- `lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart`
- `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart`
- `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart`
- `lib/features/sale/ui/view/sale_cart/widgets/sale_khqr_popup.dart`
- any branch/profile state reads needed to determine KHQR receiver availability
- KHQR-related tests under `test/sale/`

Do not change unrelated sale logic.

## Phase 0 — Baseline & Guard Conditions
- [x] Confirm source of truth for branch KHQR receiver availability
- [x] Confirm current auto-generation triggers in cart notifier
- [x] Confirm popup open/generate relationship

Output:
- one clear list of current trigger points and branch-precondition source

### Phase 0 Findings

#### A. Source of truth for branch KHQR receiver availability

Existing branch models already carry KHQR receiver configuration:

- `BranchListItem.khqrReceiverAccountId`
- `BranchListItem.khqrReceiverName`

Source files:
- `lib/features/branchV2/domain/models/branch_models.dart`
- `lib/features/branchV2/ui/viewmodels/branch_controller.dart`

This means frontend already has a valid branch-state source for preventing KHQR generation before network.

#### B. Current auto-generation trigger points

`SaleCartNotifier` currently auto-calls `_maybeAutoGenerateKhqr(...)`, which can call `generateKhqrAttempt()`.

Current trigger points:
- after `addSelection(...)`
- after `setTenderCurrency(...)`
- after `setPaymentMethod(...)`
- after `setLines(...)`
- after `setSaleType(...)`
- after `updateQuantity(...)`

Source file:
- `lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart`

This confirms KHQR initiation is currently coupled to cart mutation/state transition, not only explicit user intent.

#### C. Popup open/generate relationship

`SaleKhqrPopup` currently auto-generates on popup open:
- `initState()` schedules `_maybeGenerateOnOpen()`
- `build()` may also reschedule generation if payload is still missing

Source file:
- `lib/features/sale/ui/view/sale_cart/widgets/sale_khqr_popup.dart`

This means the current flow has **two auto-generation sources**:
- cart/viewmodel mutation path
- popup lifecycle path

#### D. Current UX conclusion

The current KHQR flow is wrong in two structural ways:

1. KHQR generation is not explicit enough.
2. Missing receiver configuration is only handled after backend rejection, even though frontend already has the branch configuration needed to prevent the call.

### Phase 0 Status

Phase 0 is complete.

## Phase 1 — Remove Auto-Generation
- [x] Remove `_maybeAutoGenerateKhqr(...)` side effects from cart mutation paths
- [x] Keep `setPaymentMethod('qr')` as state-only transition to `readyToGenerate`
- [x] Preserve supersede behavior when cart changes after an existing KHQR attempt

Output:
- cart edits no longer create KHQR intents

### Phase 1 Result

Notifier-side KHQR auto-generation has been removed from cart mutation/state paths:
- `addSelection(...)`
- `setTenderCurrency(...)`
- `setPaymentMethod(...)`
- `setLines(...)`
- `setSaleType(...)`
- `updateQuantity(...)`

Behavior now:
- switching to `QR` prepares the cart in `readyToGenerate`
- cart edits do not create KHQR intents
- if a generated KHQR already exists and the cart changes, KHQR is marked `superseded`
- regeneration still requires explicit user action

Focused test expectations were updated to match this rule:
- no payload appears immediately after selecting `QR`
- tests now call `generateKhqrAttempt()` explicitly before asserting waiting/confirmed KHQR flow
- superseded cart behavior now stays superseded instead of auto-regenerating

## Phase 2 — Add Receiver Precondition Gate
- [x] Read branch KHQR receiver availability from existing branch/profile state
- [x] Block KHQR generation when receiver is missing
- [x] Show a deterministic user-facing message before any network call

Output:
- missing receiver is prevented in UI before backend reject

### Phase 2 Result

KHQR generation now checks branch receiver availability before touching the repository:
- reads `branchControllerProvider.currentBranchProfile` first
- falls back to the matching branch entry in `branchControllerProvider.branches`
- resolves active branch id from:
  - `activeBranchContextIdProvider`
  - and falls back to `saleAccessGateProvider.branchId`

Behavior now:
- if branch state indicates no `khqrReceiverAccountId`, `generateKhqrAttempt()`:
  - stays in `readyToGenerate`
  - stores `khqrBranchReceiverNotConfigured`
  - shows the same deterministic Bakong receiver message
  - throws before any network call is attempted

Focused test coverage now proves branch-state precondition blocking even when the mock sale repository itself is configured to succeed.

## Phase 3 — Explicit Generate Flow
- [x] Define one explicit generate trigger
- [x] Ensure popup opening does not auto-generate unless that open action is the explicit trigger
- [x] Keep status polling only after a real attempt exists

Output:
- KHQR generation occurs only on explicit user intent

### Phase 3 Result

KHQR generation is now explicit from the popup flow:

- opening the KHQR popup no longer auto-generates an attempt
- selecting `QR` as payment method no longer auto-opens the popup
- the popup now exposes an explicit `Generate KHQR` / `Generate New KHQR` action
- polling/status handling remains tied to real attempt states only:
  - `waitingForPayment`
  - `pendingConfirmation`

The popup still supports the existing operator flow after a real attempt exists:
- render QR payload
- check/cancel lifecycle
- auto-close after `paidConfirmed`

Focused validation now covers:
- opening the popup in `readyToGenerate` does not auto-generate
- tapping `Generate KHQR` explicitly starts the attempt
- existing readonly/waiting-state sale-cart behavior still passes

## Phase 4 — UX Messaging & States
- [x] Refine `ready`, `superseded`, `receiver missing`, and `confirmed` messaging
- [x] Ensure QR-related buttons/labels communicate required next action clearly

Output:
- operator can understand whether they must configure, generate, regenerate, or finalize

### Phase 4 Result

KHQR operator messaging is now state-driven in both the cart callout and the popup:

- cart callout now distinguishes:
  - `Generate KHQR when the customer is ready`
  - `Cart changed. Generate a new KHQR.`
  - `KHQR is ready for customer payment.`
  - `KHQR payment is awaiting confirmation.`
  - `KHQR payment confirmed.`
  - `KHQR unavailable for this branch.`
- popup status copy now reflects the same lifecycle more clearly:
  - receiver missing shows `Receiver not configured`
  - ready state explains `tap Generate KHQR`
  - superseded/cancelled/expired explain that a fresh KHQR is required
  - pending confirmation explicitly tells the operator to re-check status before finalizing

Button labeling is now aligned with the next expected action:
- cart button:
  - `Open KHQR Generator`
  - `Review KHQR Payment`
  - `Review KHQR Status`
  - `KHQR Payment Confirmed`
  - `KHQR Unavailable`
- popup button:
  - `Generate KHQR`
  - `Generate New KHQR`

Receiver-missing UX is now blocked earlier in the visible UI:
- the cart callout disables the action button and explains the branch receiver requirement
- the popup hides the generate action if it is opened in a receiver-missing state

## Phase 5 — Regression Tests
- [x] Add/adjust tests for:
  - selecting QR does not call initiate
  - add item does not call initiate
  - cart change after generated KHQR marks superseded but does not auto-regenerate
  - missing receiver blocks initiate before network
  - explicit generate still works

### Phase 5 Result

The KHQR regression set now covers the full corrected flow:

- `test/sale/sale_cart_khqr_state_test.dart`
  - selecting `QR` leaves the cart in `readyToGenerate`
  - cart change after generation marks KHQR `superseded`
  - missing receiver blocks initiate before network
- `test/sale/sale_khqr_smoke_test.dart`
  - end-to-end generate/cancel/regenerate/finalize flow still works
- `test/sale/sale_khqr_popup_test.dart`
  - popup opening does not auto-generate
  - explicit `Generate KHQR` starts the attempt
  - receiver-missing popup hides generate action
- `test/sale/sale_cart_content_khqr_test.dart`
  - cart callout shows receiver-unavailable state
  - superseded state prompts regenerate
- `test/sale/sale_cart_readonly_test.dart`
  - waiting-state popup action/copy remains consistent after the new labels

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Baseline locked: branch receiver source + auto-generation trigger list confirmed |
| 1 | Completed | Notifier-side auto-generation removed; selecting QR now only prepares `readyToGenerate` |
| 2 | Completed | Branch-state receiver precondition now blocks KHQR initiate before network |
| 3 | Completed | Popup no longer auto-generates; explicit generate button is now the only popup trigger |
| 4 | Completed | KHQR cart/popup messaging now reflects ready, review, regenerate, confirmed, and receiver-unavailable states |
| 5 | Completed | Regression suite now covers explicit generate, superseded cart change, receiver precondition, and popup/cart KHQR messaging |
