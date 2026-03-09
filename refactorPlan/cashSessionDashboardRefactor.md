# Cash Session Dashboard Refactor

Goal: turn Cash Session into a clear operational dashboard and remove duplicated/unclear information architecture across `Session`, `Movement`, and `Report`.

Status: implementation substantially complete. The live `Session` dashboard, `Movement` simplification, and `History` taxonomy have been shipped and validated.

## Problem

Current issues:
- `Session` is under-designed, especially on wide screen.
- `Movement` duplicates `Session Overview`.
- `Report` is vague and currently mixes internal terminology (`X` / `Z`) that is not intuitive for operators.
- Wide screen leaves dead space instead of using the page as an operational dashboard.
- We need a proper place for session-bound sale rows once backend exposes the new endpoint.

## Locked UX Decisions

1. `Session` becomes the live cash-session dashboard.
2. `Movement` must no longer show `Session Overview`.
3. `Report` tab should be renamed to `History`.
4. `History` is for closed session summaries only.
5. Current-session aggregate moves into `Session`, not `History`.
6. Primary UI should not expose `X Report` / `Z Report` wording.
7. Session-bound sale rows belong under `Session`.

## Target Information Architecture

### Tabs

- `Session`
- `Movement`
- `History`

### `Session`

Purpose: live operational dashboard for the active/current branch cash session.

Contains:
- `Session Overview`
- `Current Session Summary`
- `Session Actions`
- `Session Sales`

### `Movement`

Purpose: manual cash operations only.

Contains:
- manual paid in / paid out / adjustment actions
- optional recent manual movement history if useful

Does not contain:
- `Session Overview`
- current session summary duplication

### `History`

Purpose: closed session history only.

Contains:
- closed session summaries
- date-based lookup / reload flow

Internal mapping:
- current open-session aggregate = previous `X` concept
- closed session summary = previous `Z` concept

But those words should not be primary UI labels.

## Target Layout

### Wide Screen

`Session` page:

- Top section:
  - Left column:
    - `Session Overview`
    - `Current Session Summary`
  - Right column:
    - `Session Actions`
- Bottom section:
  - full-width `Session Sales` table

### Mobile Screen

`Session` page:

1. `Session Overview`
2. `Session Actions`
3. `Current Session Summary`
4. `Session Sales`

`Session Sales` should render as compact cards/list rows on mobile, not a desktop table.

## Data Ownership

### `Session`

Needs:
- active session state
- current session aggregate
- session-bound sale rows

Current status:
- active session state exists
- current session aggregate is partially represented through current cash session + existing report logic
- session-bound sale rows are now wired from `GET /v0/cash/sessions/:sessionId/sales`

### `Movement`

Needs:
- manual movement commands
- optional manual movement history

Current status:
- mostly implemented
- layout/ownership needs cleanup

### `History`

Needs:
- closed session summary flow

Current status:
- current `Z Report` page already provides the primary backend-backed behavior
- needs UX reframing under `History`

## Completed Backend Dependency

`Session Sales` is now powered by:
- `GET /v0/cash/sessions/:sessionId/sales`

Current implementation:
- `Session` page lower section now renders `Session Sales`
- wide: table
- mobile: compact list cards
- clean empty states for no active session / no session sales yet

## Refactor Phases

### Phase 0 — Lock Taxonomy
- [x] Rename mental model:
  - `Session`
  - `Movement`
  - `History`
- [x] Remove `X Report` / `Z Report` wording from primary UI plan

### Phase 1 — Rebuild `Session`
- [x] Wide layout:
  - overview + current summary on left
  - actions on right
  - full-width lower section
- [x] Mobile layout:
  - stacked dashboard order
- [x] Introduce `Current Session Summary` card

### Phase 2 — Add `Session Sales`
- [x] Wire the new backend session-sales endpoint
- [x] Wide: table
- [x] Mobile: list/card rows
- [x] Keep fallback/empty state clean

### Phase 3 — Simplify `Movement`
- [x] Remove duplicated `Session Overview`
- [x] Keep manual movement ownership only
- [x] Keep recent manual-only history on this tab

### Phase 4 — Replace `Report` with `History`
- [x] Rename tab label to `History`
- [x] Reframe current `Z Report` UI as closed session history
- [x] Remove live current-session summary from this tab

### Phase 5 — Cleanup
- [x] Remove stale report terminology in primary user-facing widgets where appropriate
- [x] Remove duplicated layout/components made obsolete by the new dashboard
- [x] Update tests for tab labels and screen composition

## Open Questions

1. Should `History` remain a single generated summary card for a selected date, or evolve into a list of closed-session summaries for that date?
2. Do we want a standalone deep-linkable `Session Summaries` page to remain available internally, or should all operator-facing history stay under `History` only?

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | `Session / Movement / History` taxonomy is now the shipped primary UI model |
| 1 | Completed | `Session` is now a live dashboard with overview, current summary, actions, and session sales |
| 2 | Completed | `Session Sales` now uses the canonical session sales endpoint on wide + mobile |
| 3 | Completed | `Movement` no longer duplicates session overview and now focuses on manual movement + manual history |
| 4 | Completed | `History` now owns the old Z-report behavior with clearer operator-facing language |
| 5 | Completed | Tests and user-facing terminology were updated to reflect the new dashboard composition |
