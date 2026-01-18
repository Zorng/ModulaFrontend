# Widgets (Reuse, Composition, and Shared Widget Structure)

## Reuse-first
- Check existing widgets before creating new ones:
  - `lib/core/widgets/` (shared)
  - `lib/features/<feature>/ui/widgets/` (feature-local)

Practical workflow:
1) Search the feature’s `ui/widgets/` first.
2) Search `lib/core/widgets/` for an existing reusable primitive (cards, key-value rows, empty states, buttons).
3) Only then create a new widget.

## Shared vs feature-local
- Used in 2+ features → promote to `lib/core/widgets/`.
- Used only in one feature → keep in `lib/features/<feature>/ui/widgets/`.
- If duplication is unavoidable, keep it minimal and create a Jira follow-up to dedupe.

## Screen composition (practical)
- Screen/page files should not declare large custom widget classes.
- At most one small private widget is allowed if it stays trivial (≈ ≤30 LOC).
- Extract meaningful sections (not many tiny widgets).

## Naming & files
- Prefer descriptive widget names over generic ones:
  - Good: `BranchSelectorSheet`, `InventoryOnHandCard`, `XReportSummaryCard`
  - Avoid: `MyWidget`, `Card2`, `WidgetA`
- Keep widget file names aligned with widget names (snake_case).

## Core widget categorization
To avoid a junk drawer, `lib/core/widgets/` should be grouped by UI role, e.g.:
- `layout/`
- `navigation/`
- `forms/`
- `feedback/`
- `display/`
- `buttons/`
- `media/`

Current structure (kept intentionally small):
- `lib/core/widgets/buttons/`
- `lib/core/widgets/display/`
- `lib/core/widgets/forms/`
- `lib/core/widgets/layout/`
- `lib/core/widgets/media/`
- `lib/core/widgets/navigation/`
- `lib/core/widgets/widget_gallery_page.dart` (dev-only)

## Widget gallery
See `handbook/architecture/widget_gallery.md` for how to preview shared widgets in `lib/core/widgets/widget_gallery_page.dart`.

## Promote later (parallel development)

When two teammates build similar UI in parallel:
- It’s acceptable to build feature-local widgets first to avoid blocking.
- Create a Jira ticket to:
  - dedupe the implementations, and
  - promote the chosen widget to `lib/core/widgets/` once used by 2+ features.

This prevents the project from stalling while still keeping long-term duplication under control.
