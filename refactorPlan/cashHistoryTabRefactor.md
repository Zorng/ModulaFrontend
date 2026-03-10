# Cash Session History Tab Refactor

Goal: turn `Cash Session > History` into a true closed-session history surface with list-first browsing, optional date filtering, and session-detail drill-down.

## Scope
- `lib/features/cash_session/ui/view/cash_history/`
- `lib/features/cash_session/ui/viewmodels/`
- `lib/features/cash_session/data/`
- `lib/features/reporting/data/` only where needed to stop using the old date-aggregate-first flow

## Revision Note
- Revised after initial phase 2/3 implementation.
- Previous design:
  - wide split view (`table | detail`)
  - mobile expandable cards with inline detail
- Rejected because:
  - wide split view is not the desired UX for this feature
  - mobile inline detail is weaker than a dedicated detail screen
  - date picker should act as a filter, not the primary session-selection mechanism

## Locked UX Direction
- `History` means:
  - list of closed sessions
  - sorted by most recent closed session first
  - optional date filter
  - then inspect one selected closed session summary
- The UI must not expose `Z Report` terminology in primary labels.
- `History` must work for both:
  - owner/admin/manager
  - cashier/staff
- Backend self-scope rules should reduce visible rows naturally; the UI model stays the same.

## Canonical Data Ownership
- Primary history list:
  - `GET /v0/cash/sessions?status=closed|force_closed&from=ISO&to=ISO&limit=50&offset=0`
- Closed-session detail:
  - `GET /v0/cash/sessions/:sessionId/z`

## Filter Model
- Default load:
  - no explicit date filter
  - list most recent closed sessions first
- Date picker role:
  - filter the list
  - not the primary way to discover sessions
- Required controls:
  - apply date filter
  - clear date filter

## Screen Model

### Wide
- top controls:
  - optional date filter
  - clear filter action
  - session count / pagination context
- main content:
  - full-width paginated table of closed sessions
- row click:
  - opens a large scrollable dialog showing `Closed Session Summary`

### Mobile
- top controls:
  - optional date filter
  - clear filter action
- main content:
  - closed session cards
  - most recent closed session first
- card tap:
  - navigates to a full-page detail screen with back button

## History Item Display
Each list row/card should show:
- `Status`
- `Opened by`
- `Opened at`
- `Closed at`

Mobile note:
- since the list may already be filtered by date, prefer concise timestamps if full date-time causes wrapping
- if needed, show time-first or compact date-time formatting

## Closed Session Summary Display
The selected session detail should show:
- opening float
- expected cash
- counted cash
- variance
- cash sales
- KHQR sales
- paid in
- paid out

## Labels
- page title: `History`
- list section: `Closed Sessions`
- detail surface title: `Closed Session Summary`

Avoid:
- `Z Report`
- `Generate report`

## Empty States
- no rows with no filter:
  - `No closed sessions found.`
- no rows for selected date:
  - `No closed sessions found for this date.`

## Phases

### Phase 0 — Lock Model
- [x] Lock list-first history model
- [x] Lock route/data ownership

### Phase 1 — History List State
- [x] Support recent-first default loading
- [x] Support optional date filter + clear filter
- [x] Track selected session id / selected session route target
- [x] Expose count/loading/error state
- [x] Expose pagination state for wide list

### Phase 2 — Wide History UI
- [x] Replace current wide split view with full-width paginated table
- [x] Add row click -> large scrollable dialog
- [x] Remove right-column placeholder pattern

### Phase 3 — Mobile History UI
- [x] Replace current inline expandable detail with full-page detail route
- [x] Keep card list newest-first
- [x] Ensure compact date/time formatting prevents broken card layout

### Phase 4 — Closed Session Detail Loading
- [x] Load per-session `z` only when selected
- [x] Show loading/error/data states without freezing
- [x] Reuse the same summary content across:
  - wide dialog
  - mobile detail page

### Phase 5 — Cleanup
- [x] Remove old date-aggregate-first assumptions
- [x] Remove any leftover `Z Report` primary UI wording from history flow
- [x] Remove superseded split-view / inline-detail code
- [x] Update tests

## Notes
- This refactor is about `History` UX and state flow, not the standalone admin-only `xReport` route.
- The current in-progress implementation should be treated as superseded by this revised plan.
