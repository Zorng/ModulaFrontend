# Widgets (Reuse, Composition, and Shared Widget Structure)

## Reuse-first
- Check existing widgets before creating new ones:
  - `lib/core/widgets/` (shared)
  - `lib/features/<feature>/ui/widgets/` (feature-local)

## Shared vs feature-local
- Used in 2+ features → promote to `lib/core/widgets/`.
- Used only in one feature → keep in `lib/features/<feature>/ui/widgets/`.
- If duplication is unavoidable, keep it minimal and create a Jira follow-up to dedupe.

## Screen composition (practical)
- Screen/page files should not declare large custom widget classes.
- At most one small private widget is allowed if it stays trivial (≈ ≤30 LOC).
- Extract meaningful sections (not many tiny widgets).

## Core widget categorization
To avoid a junk drawer, `lib/core/widgets/` should be grouped by UI role, e.g.:
- `layout/`
- `navigation/`
- `forms/`
- `feedback/`
- `display/`
- `buttons/`
- `media/`

