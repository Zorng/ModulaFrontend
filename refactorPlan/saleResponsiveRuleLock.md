# Sale Responsive Rule Lock

Goal: keep sale responsive behavior aligned with the app-wide navigation model.

## Locked Rule

- **Not wide screen** (`width < 1024`)
  - enter sale from the **portal**
  - cart is a **tab**
  - no persistent side cart panel
  - one coherent mobile/tablet sale presentation

- **Wide screen** (`width >= 1024`)
  - enter sale from the **navigation rail**
  - cart is a **persistent side panel**
  - no cart tab in the wide bottom navigation

This means the structural breakpoint that matters for sale is:
- `AppBreakpoints.isLarge(width)`

`small` / `medium` may still be used for local spacing/density tweaks, but they must not create a third structural sale mode.

## Why This Is Locked

The sale shell already follows a 2-mode structure:
- not large -> mobile bottom-nav shell
- large -> wide shell with side cart

If inner sale widgets introduce their own medium-specific structure, the user gets a hybrid tablet state that feels inconsistent with the rest of the app.

## Impact Scan

### Aligned With The Rule

- `lib/features/sale/ui/view/sale_shell/sale_bottom_nav_shell_page.dart`
  - already uses `AppBreakpoints.isLarge(...)` as the structural switch
  - below large -> cart remains a tab
  - at large -> cart becomes a side panel

- `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart`
  - now only shows the dedicated cart header in wide mode
  - no extra medium-only shell/personality remains

- `lib/features/sale/ui/view/sale/sale_page.dart`
  - now uses one not-large presentation and one large presentation
  - no explicit medium-specific branch remains

### Remaining Width-Driven Behavior (Acceptable For Now)

- `lib/features/sale/ui/view/sale/widgets/sale_page_menu_catalog.dart`
  - still uses fitting-column logic based on available width
  - below large, the grid can naturally render different column counts as width grows
  - this is content-density adaptation, not a structural sale mode

- `lib/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart`
  - uses `isLarge` to switch between wide and not-wide detail presentation
  - this is aligned with the locked rule

- `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_readonly_banner.dart`
  - uses a narrow-width helper at `350px`
  - this is a local content-fit rule, not a breakpoint mode

## What Still Might Feel Like A “Third Breakpoint”

Even with the structural rule cleaned up, users may still perceive a third mode below `1024` because the menu grid gets denser as width increases.

That is caused by:
- responsive column fitting in `SalePageMenuCatalog`

This is not currently classified as a navigation/layout bug unless it creates:
- overflow
- inconsistent control placement
- cart/shell behavior differences

## Follow-Up Trigger

Open a follow-up refactor only if one of these happens:
- sale below `1024` still feels structurally different at `640..1023`
- the menu grid density creates usability issues on tablet widths
- more medium-only logic is introduced into sale widgets

## Verification Checklist

- below `1024`, sale uses the bottom-nav shell and cart tab
- at `1024+`, sale uses the side cart panel
- no wide-only cart header/UI appears below `1024`
- no extra medium-only sale shell behavior exists
