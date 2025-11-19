# Theme Application Guide

This guide summarizes how we apply theming across widgets so screens stay consistent and easy to maintain.

## Core principles
- **Use ThemeData first**: Prefer `Theme.of(context)` for colors, text, and component theming. Avoid hard‑coded colors and font sizes unless strictly necessary.
- **Typography**: Use the shared `TextTheme` styles (e.g., `labelMedium`, `labelLarge`, `bodyMedium`). Do not override `color` unless you are on a colored surface and need contrast; otherwise the `TextTheme` color should be used.
- **Buttons**: Let the button’s style own the text/icon color. Pick size/weight from `TextTheme` (copy without color), and rely on the button `foregroundColor` (primary = white, secondary = onSurface).

## Shared button helpers (preferred)
- Use `AppButtons.primary(context)` for primary actions (e.g., login, add). It sets `backgroundColor: primary`, `foregroundColor: onPrimary`, radius 12, height 48, and `labelLarge` text sizing.
- Use `AppButtons.secondary(context)` for neutral actions; it uses `surface`/`onSurface`.
- When a compact inline action is needed (e.g., beside a search bar), pass `compact: true` to tighten padding/density while keeping the same color rules.
- If you need a different text size/weight, pass `textStyle: Theme.of(context).textTheme.labelMedium` (or similar); the helper will apply the right color.

## Inputs
- Use the global `InputDecorationTheme` (rounded corners, filled) via `TextField`/`TextFormField`. Only override label or suffix/prefix icons; avoid custom borders/colors unless required.

## Surfaces and backgrounds
- Use `colorScheme` values for backgrounds/backdrops (e.g., `surface`, `surfaceContainerHighest`) instead of raw whites/greys. Gradients are defined in `AppGradients` when needed.

## Responsiveness & typography
- Use `AppBreakpoints` for width checks; avoid scattering magic numbers. When adjusting sizes, branch on `AppBreakpoints.isSmall/Medium/Large` and use the nearest `TextTheme` size rather than custom numbers.

## Do / Don’t examples
- **Do**: `FilledButton(style: AppButtons.primary(context), child: const Text('Save'))`
- **Don’t**: `FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.orange), child: Text('Save', style: TextStyle(color: Colors.white)))`
- **Do**: `Text('Title', style: Theme.of(context).textTheme.titleMedium)`
- **Don’t**: `Text('Title', style: TextStyle(fontSize: 18, color: Colors.black))`

## When to diverge
- Only diverge from the theme for exceptional cases (e.g., critical alerts). Encapsulate those in reusable widgets so overrides don’t leak across the codebase.
