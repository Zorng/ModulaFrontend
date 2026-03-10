# Cash Movement Tab Refactor

Goal: turn `Movement` into a clear manual cash-operations screen with intentional wide-screen layout, correct control states, and reliable mutation UX.

Status: planning only. No implementation from this artifact has started yet.

## Problem

Current issues:
- selected `Paid In / Paid Out` and currency buttons disappear visually because selected foreground and background colors conflict
- wide-screen layout is still the mobile form stretched horizontally
- no-session state is noisy because the full disabled form remains visible below the warning
- submit UX is misleading: the form clears and shows success before backend confirmation
- `Adjustment` exists in the data layer and history but is missing from the form UI
- manual movement history is too shallow for an operational ledger

## Locked UX Decisions

1. `Movement` is for manual cash operations only.
2. `Movement` must not reintroduce full `Session Overview`.
3. Wide screen must use a dedicated layout, not a stretched mobile form.
4. Mutation success must be shown only after backend confirmation.
5. `Adjustment` must become a first-class movement type in the form.
6. No-session state should use a focused empty-state treatment, not a disabled full form.

## Target Information Architecture

### Purpose

`Movement` handles:
- `Paid In`
- `Paid Out`
- `Adjustment`
- recent manual movement history

It does not handle:
- live session overview duplication
- current session summary
- session sales
- historical closed-session summaries

## Target Layout

### Wide Screen

- Top section:
  - left: `Manual Movement Form`
  - right: `Session Context` / `Movement Guidance`
- Bottom section:
  - full-width `Manual Movement History`

`Manual Movement Form` should be intentionally composed for wide:
- row 1: movement type segmented controls
- row 2: currency segmented controls
- row 3: amount + reason side by side when space allows
- row 4: primary action

### Mobile Screen

Mobile can stay closer to the current composition, but still needs polish:
1. no-session empty state or context strip
2. movement form
3. manual movement history

## Behavior Rules

### When Session Is Open

- form is enabled
- movement type options:
  - `Paid In`
  - `Paid Out`
  - `Adjustment`
- submit:
  - shows loading
  - waits for backend confirmation
  - clears form only on success
  - shows deterministic error on failure

### When No Session Is Open

- do not show the full disabled form
- show a focused empty state:
  - message: manual movements require an open cash session
  - CTA: `Open Cash Session`

### History

- history section shows manual movements only
- row model:
  - time
  - type
  - reason
  - USD
  - KHR
- first pass can stay recent-only, but should have a clear path to:
  - `View more`
  - pagination
  - type/date filtering

## Visual Decisions

### Segmented Controls

Selected state:
- orange background
- white text/icon

Unselected state:
- neutral background
- dark text/icon
- visible border

This applies to:
- movement type
- currency

### Wide Screen Tone

- form should feel compact and deliberate, not tall and stretched
- history table styling should stay aligned with other wide-screen tables
- lightweight context/help panel is allowed on the right side, but it must not duplicate the whole session screen

## Refactor Phases

### Phase 0 — Lock Scope
- [x] confirm `Movement` as manual cash operations only
- [x] lock the current UX issues and target layout

### Phase 1 — Fix Control Styling
- [x] fix selected button contrast for:
  - movement type
  - currency
- [x] verify active/inactive/disabled states

### Phase 2 — Rebuild No-Session State
- [x] replace disabled full form with focused empty state
- [x] keep CTA to `Open Cash Session`

### Phase 3 — Recompose Wide Form Layout
- [x] build an intentional wide-screen form layout
- [x] avoid simple horizontal stretching of the mobile form
- [x] add `Adjustment` as a first-class movement type

### Phase 4 — Fix Submit UX
- [x] await backend confirmation before success feedback
- [x] clear form only after success
- [x] preserve inputs on failure
- [x] show deterministic error message

### Phase 5 — Improve Manual History
- [x] review row density and readability
- [x] decide whether to add `View more`, pagination, or filtering
- [x] keep history scoped to manual movements only

### Phase 6 — Cleanup
- [x] remove dead or modal-era movement UI that is no longer used
- [x] align tests with the new movement UX

## Open Questions

1. Should wide-screen `Session Context` show only a short explanation, or also a minimal branch/session label strip?
2. Do we want `Adjustment` visually separated from `Paid In / Paid Out`, or treated as the same segmented group?
3. Should manual history remain recent-only in the first implementation pass, or include `View more` immediately?

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Scope and target UX are locked |
| 1 | Completed | Selected movement/currency controls now keep visible white-on-orange contrast and basic widget coverage exists for selected + disabled states |
| 2 | Completed | No-session movement now uses a focused empty-state card with CTA instead of rendering a disabled full form |
| 3 | Completed | Wide layout now uses a dedicated form + context panel composition, and `Adjustment` is a first-class movement type in the form/tests |
| 4 | Completed | Submit now awaits the backend result, shows loading, clears only on success, and preserves user input with deterministic error feedback on failure |
| 5 | Completed | Manual history now stays manual-only, uses denser rows/badges, and adds a first-pass `View all / View less` path instead of jumping straight to pagination |
| 6 | Completed | Removed the unused modal-era cash movement widget and kept movement coverage aligned with the rebuilt card/page/history UX |
