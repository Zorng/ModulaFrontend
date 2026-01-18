# Testing & Quality Gate

## CI gates (non-negotiable)
- `flutter analyze`
- `flutter test`

CI workflow: `.github/workflows/ci.yml`

## Minimum expectations
- Bug fixes: add a regression test when feasible.
- New behavior/use cases: add at least one test (prefer unit; widget when UI logic is involved).
- UI-only styling/layout changes: tests optional; include screenshots + manual test steps.
- Refactors: new tests optional only if existing tests cover the touched behavior.

## Exceptions
If no test is added, include a brief reason and (when relevant) a follow-up Jira ticket to add coverage.

## Local commands
- `flutter analyze`
- `flutter test`
