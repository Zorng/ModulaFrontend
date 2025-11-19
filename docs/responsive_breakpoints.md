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
- **Portal shell**: uses `AppBreakpoints.isLarge(width)` to decide when to show a side rail vs. chips.
- **Search + Add bar**: uses `AppBreakpoints.compact` to tighten spacing on narrow screens.

## How to Apply
- Import `package:modular_pos/core/theme/responsive.dart`.
- Use the helper methods instead of hardcoded numbers to decide layout changes (column vs. row, grid counts, padding, etc.).
- Adjust `responsive.dart` values if the design system changes; all consumers will pick up the new breakpoints automatically.

## Notes
- Breakpoints are device-width based; keep font/spacing tweaks in mind when moving between tiers.
- Aim to avoid scattering magic numbers; always rely on `AppBreakpoints` for width checks.
