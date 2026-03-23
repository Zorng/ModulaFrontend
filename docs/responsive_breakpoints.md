# Responsive Breakpoints

This app uses shared breakpoints to keep layouts and sizing consistent across screens. The definitions live in `lib/core/theme/responsive.dart`.

## Breakpoint Rules
- `compact`: 520px – very narrow mobile widths.
- `small`: 640px – mobile-first breakpoint (default mobile styling below this).
- `medium`: 1024px – tablet/desktop breakpoint; layouts often add side rails or multi-column grids above this.

Helpers:
```dart
AppBreakpoints.isSmall(width);  // width < 640
AppBreakpoints.isMedium(width); // 640 <= width < 1024
AppBreakpoints.isLarge(width);  // width >= 1024
```

## Usage Examples
- **Login view**: checks `AppBreakpoints.isSmall(constraints.maxWidth)` to switch between mobile and desktop form layouts.
- **Portal shell**: uses `AppBreakpoints.isLarge(width)` to decide when to show the wide rail shell vs. the mobile portal.
- **Search + Add bar**: uses `AppBreakpoints.compact` to tighten spacing on narrow screens.

## Navigation behavior by breakpoint
The breakpoint system is still global, but navigation now differs by **workspace type** as well as width.

- **Tenant workspace**
  - `small/compact/medium`:
    - tenant portal remains the feature hub
    - some tenant feature roots still use feature-local bottom tabs
  - `large`:
    - persistent left **NavigationRail** + content area
    - no back button on tenant feature roots

- **Branch workspace**
  - all breakpoints:
    - branch shell uses an app bar + hidden drawer
    - drawer opens from the app-bar leading slot
    - branch workspace does **not** switch to a rail on wide screens
  - branch feature roots may still use feature-local bottom tabs where needed

- **Sale layout**
  - below `large`:
    - cart remains a sale tab
  - `large`:
    - cart moves into the sale root as a side panel
    - there is no separate medium-only sale navigation mode

## How to Apply
- Import `package:modular_pos/core/theme/responsive.dart`.
- Use the helper methods instead of hardcoded numbers to decide layout changes (column vs. row, grid counts, padding, etc.).
- Adjust `responsive.dart` values if the design system changes; all consumers will pick up the new breakpoints automatically.

## Notes
- Breakpoints are device-width based; keep font/spacing tweaks in mind when moving between tiers.
- Aim to avoid scattering magic numbers; always rely on `AppBreakpoints` for width checks.
