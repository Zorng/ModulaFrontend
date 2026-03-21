# Sale Wide Layout Rebalance

Goal: improve the wide-screen sale experience by rebalancing space between the menu catalog and the cart side panel.

## Problem

Current wide sale layout has two related issues:

1. The cart side panel is too narrow.
   - The panel uses a fixed width and feels cramped for cart items, payment controls, and checkout actions.

2. Sale menu cards become awkwardly large on very wide screens.
   - Wide sale currently behaves like “4 columns forever”.
   - As the screen gets wider, those 4 cards stretch too much.

These problems are connected:
- cart stays narrow
- menu area keeps growing
- item cards balloon

## Locked Direction

- Wide sale should be rebalanced as one layout problem, not two separate tweaks.
- Cart width should be **adaptive/clamped**, not fixed forever.
- Wide sale grid should use **adaptive column count / target tile width**, not fixed `4` columns on all large screens.
- Below wide (`< 1024`), no change:
  - portal entry
  - cart remains a tab

## Intended Result

On wide screens:
- cart gets more readable width
- menu cards stay visually sane on large monitors
- the sale screen feels balanced on:
  - 13-inch laptop
  - tablet landscape / portrait where applicable
  - full-screen desktop monitor

## Phase 0 — Impact Scan
- [x] Confirm current fixed cart width in the wide sale shell
- [x] Confirm current wide sale grid cap/path
- [x] Identify any tests tied to current width assumptions

### Findings

- The wide cart panel is currently fixed at `360` in:
  - `lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart`
- The sale page still caps wide catalog density at `4` columns in:
  - `lib/features/sale/ui/view/sale/sale_page.dart`
- The catalog then applies fitting logic within that cap in:
  - `lib/features/sale/ui/view/sale/widgets/sale_page_menu_catalog.dart`
  - so wide screens still behave like “up to 4 stretched cards” instead of “more columns with sane card width”
- Existing test surface is light for this exact layout behavior:
  - `test/sale/sale_page_readonly_test.dart`
  - `test/sale/sale_cart_readonly_test.dart`
  - no existing widget test currently locks the wide sale width distribution itself

## Phase 1 — Cart Width Strategy
- [x] Replace fixed cart width with a clamped responsive width
- [x] Verify cart still behaves well on smallest wide breakpoint

### Phase 1 Result

- Wide cart width is now clamped in:
  - `lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart`
- Current strategy:
  - factor: `32%` of wide viewport
  - min: `360`
  - max: `460`
- This preserves the existing feel on the smallest wide screens while giving the cart more room on large desktop widths.

## Phase 2 — Wide Catalog Density Strategy
- [x] Stop treating wide as fixed `4` columns forever
- [x] Move to adaptive wide columns based on available width / target tile width
- [x] Keep card sizing sane on large desktop monitors

### Phase 2 Result

- Wide sale no longer caps the catalog at `4` columns in:
  - `lib/features/sale/ui/view/sale/sale_page.dart`
- The wide grid cap is now `6`, while:
  - smaller wide screens still naturally settle at `4` because of the existing fitting logic in `SalePageMenuCatalog`
  - larger desktop screens can grow to `5` or `6` columns instead of stretching `4` oversized cards
- This keeps the current good laptop behavior while preventing card ballooning on large monitors.

## Phase 3 — Rebalance Validation
- [ ] Check combined wide layout after both changes
- [ ] Verify no regressions on:
  - small wide screens
  - large desktop monitors
  - sale cart side panel readability

## Validation
- [ ] `flutter analyze`
- [ ] relevant sale widget tests
- [ ] manual check on:
  - laptop-sized wide viewport
  - large desktop viewport
