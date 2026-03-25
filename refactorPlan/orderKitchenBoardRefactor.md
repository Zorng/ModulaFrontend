# Order Kitchen Board Refactor

Goal: redesign the fulfillment order UI into a clearer kitchen-oriented board/list experience inspired by the reference layout, while keeping navigation, void workflow, and mobile behavior consistent with the current product model.

## Why This Exists

The current order UI works, but it is visually weak and structurally too generic for a high-throughput kitchen/fulfillment workspace.

Current issues:
- the current order list feels like a plain vertical feed
- fulfillment status filtering is functional but not visually strong
- card identity is weak
- the layout does not read as an operational board

At the same time, we must avoid mixing this redesign with unrelated concerns:
- shell navigation is already owned elsewhere
- sale void workflow needs its own dedicated detail page
- notification routing should not dictate the order-board layout

## Design Inspiration Assessment

The attached reference is a good fit for:
- the **Kitchen** / fulfillment-active workspace

It is **not** a direct fit for:
- shell navigation
- external claim review
- void approval workflow

So this refactor should apply to:
- `OrderPage` kitchen workspace

and should not blindly replace:
- external claims workspace
- sale detail / void workflow UI

## Current Frontend State

Relevant current files:
- `lib/features/sale/ui/view/order/order_page.dart`
- `lib/features/sale/ui/view/order/widgets/order_card.dart`
- `lib/features/sale/ui/view/order/widgets/order_filters_bar.dart`
- `lib/features/sale/ui/view/order/widgets/order_status_bottom_sheet.dart`
- `lib/features/sale/ui/view/order_detail/order_detail_page.dart`

Current structure:
- top-level tabs:
  - `Kitchen`
  - `External Claims`
- kitchen filters:
  - date picker
  - one selected fulfillment status at a time
- list:
  - single-column cards
  - tap opens order detail modal
- status pill can open fulfillment-status bottom sheet

## Locked Direction

### 1) This is a fulfillment board, not a void workflow page

The board is for:
- scanning fulfillment work
- opening order detail
- changing fulfillment status where valid

It is not the final home for:
- approved void flow
- finalized-sale review workflow

Those belong to the sale/detail workflow tracked in:
- `refactorPlan/saleVoidWorkflowUi.md`

### 2) Card identity should be stronger

Current weak identity:
- `Order No. xxx`

Target identity:
- backend-supported ticket identity once available
- temporary fallback = existing order number

Planned header direction:
- main title: `Ticket #12` once supported
- fallback until backend supports it: current order number label

### 3) Top-right card affordance should be contextual overflow

The kebab menu may replace the duplicate trailing `#xx` style from the reference.

But:
- kebab must not be a blunt `Void order` shortcut
- it should expose contextual actions based on role/state

Examples:
- fulfillment actions
- open detail
- request void (later, when sale detail integration exists)

Not:
- direct order cancellation as a substitute for void

### 4) Mobile should not mimic the wide grid literally

Wide:
- multi-column board/grid

Small:
- single-column stacked list
- same information hierarchy
- horizontally scrollable status chips

So the design system remains consistent, but layout changes by breakpoint.

## Proposed UI Contract

## Wide (`large`)

### Top controls
- page title
- horizontally arranged fulfillment-status chips with counts
- date control

### Board content
- multi-column card grid
- cards optimized for scanning

### Card structure
- header:
  - `Ticket #...` or fallback order number
  - kebab overflow
- meta:
  - placed time
  - dine in / takeaway / delivery
  - optional table/location if available later
- line preview:
  - top 1-3 lines only
- footer:
  - fulfillment status pill
  - optional compact amount/summary if useful

## Small / Medium

### Top controls
- horizontally scrollable fulfillment-status chips with counts
- compact date control

### Content
- single-column stacked cards

### Mobile card structure
- same hierarchy as wide
- fewer preview lines
- tighter spacing
- no attempt to fake a dense desktop board

## Status Model

The kitchen board should reflect fulfillment state, not sale financial state.

Primary statuses for this board:
- `pending`
- `in_prep`
- `ready`
- `delivered`
- `cancelled`

Important rule:
- `cancelled` remains a fulfillment result state
- for finalized-sale void flow, it should be downstream of approved void, not treated as a casual peer action

This board may show cancelled items, but should not redefine the void model.

## Detail Behavior

Card tap:
- opens existing order detail for now

Later:
- if/when ticket-level detail is promoted, the board can route there

This tracker does not change the underlying detail owner yet.

## Non-Goals

This tracker does not cover:
- account/global notification modal
- sale void workflow page implementation
- external claims redesign beyond avoiding regressions
- shell navigation redesign

## Phase Plan

## Phase 0 — Inventory Current Order UI
- [ ] inventory kitchen tab, filters, card content, and detail entry
- [ ] identify which current fields support the new board design
- [ ] identify backend gaps such as missing ticket number / table label

Output:
- one inventory of what can be reused now vs later

## Phase 1 — Lock UI Contract
- [ ] lock wide board layout
- [ ] lock small-screen stacked-list adaptation
- [ ] lock card structure
- [ ] lock kebab semantics as contextual overflow, not direct void

Output:
- stable order board design contract

## Phase 2 — Status Filter / Header Refactor
- [ ] redesign the status filter row into chip-style filters with counts
- [ ] keep date filtering intact
- [ ] ensure external claims workspace does not inherit kitchen-only styling in the wrong way

Output:
- stronger board header/filter experience

## Phase 3 — Order Card Redesign
- [ ] redesign `OrderCard` to match the new hierarchy
- [ ] support wide-grid and stacked-mobile presentation
- [ ] add temporary fallback identity until ticket number exists

Output:
- new kitchen board cards

## Phase 4 — Wide Board Layout
- [ ] convert kitchen workspace from single-column list to responsive board/grid on wide
- [ ] preserve mobile/small stacked list
- [ ] validate density and readability

Output:
- wide kitchen board works

## Phase 5 — Contextual Actions
- [ ] introduce kebab overflow on cards
- [ ] define current safe actions
- [ ] keep void/sale-detail integration deferred or explicitly linked to sale workflow tracker

Output:
- card actions become extensible without overloading the main card

## Phase 6 — Validation
- [ ] `flutter analyze`
- [ ] targeted `flutter test`
- [ ] manual QA across:
  - wide kitchen board
  - small-screen list
  - status filtering
  - order detail opening
  - contextual actions

Output:
- validated order board redesign

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Existing kitchen tab, external claims split, modal detail entry, and current backend gaps inventoried from `OrderPage`, `OrderCard`, `OrderFiltersBar`, and `OrderDetailPage`. |
| 1 | Complete | Locked board contract: kitchen-only redesign, ticket-style fallback identity, kebab as contextual overflow, wide grid vs. stacked mobile list. |
| 2 | Complete | Header refactored into a stronger kitchen board section with date control plus fulfillment-status chips carrying live counts. |
| 3 | Complete | `OrderCard` redesigned with stronger identity, meta row, line preview, helper copy, and amount/footer hierarchy. |
| 4 | Complete | Kitchen tab now uses a responsive grid on `large` while preserving stacked cards on smaller widths; external claims remains list-based. |
| 5 | Complete | Contextual kebab actions added with current safe actions: open detail everywhere and update fulfillment status for mutable kitchen rows. |
| 6 | Complete | Targeted analyzer/test coverage passed; manual QA checklist documented for later human pass. |

## Phase 0 Output

Reusable today:
- existing `Kitchen` / `External Claims` workspace split
- date filter and single active fulfillment status
- existing order detail modal entry
- current order number, placed time, order type, line preview, and total fields
- current fulfillment status update sheet

Known backend/product gaps still deferred:
- no dedicated backend ticket number yet
- no table/location metadata on current order summaries
- no void workflow integration on the kitchen board

## Phase 1 Output

Implemented contract:
- kitchen board only; external claims intentionally kept more conservative
- fallback identity is `Ticket <current-order-number>` until real ticket numbering lands
- kebab overflow is contextual and non-destructive
- wide screens use a board/grid; small and medium use a stacked list

## Phase 6 Validation

Automated validation:
- `flutter analyze lib/features/sale/ui/view/order/order_page.dart lib/features/sale/ui/view/order/widgets/order_card.dart lib/features/sale/ui/view/order/widgets/order_filters_bar.dart test/sale/order_page_test.dart`
- `flutter test test/sale/order_page_test.dart`

Manual QA checklist:
- wide kitchen board shows a multi-column layout with readable density
- small/medium kitchen stays stacked with scrollable status chips
- status chip switching updates the visible queue correctly
- card tap still opens the existing order detail modal
- kebab menu exposes only safe current actions
- external claims tab still loads claim-only rows and does not inherit kitchen header styling
| 1 | Not started |  |
| 2 | Not started |  |
| 3 | Not started |  |
| 4 | Not started |  |
| 5 | Not started |  |
| 6 | Not started |  |
