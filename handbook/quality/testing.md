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

## Test types (what goes where)

- Unit tests (fast):
  - DTO parsing and mapping
  - repositories (with mocked API)
  - pure “store/controller” logic that doesn’t need a widget tree
- Widget tests (medium):
  - verify a page renders loading/error/data
  - verify buttons are enabled/disabled correctly
  - verify navigation events are triggered (without relying on a real backend)
- Integration tests (slow; later milestone):
  - end-to-end smoke flows on Android/iOS devices/emulators
  - keep the suite small and stable

## Folder conventions

```
test/
├─ <feature>/                      # tests grouped by feature
│  ├─ ..._test.dart
├─ fixtures/                       # stable sample payloads
│  ├─ <feature>/...
└─ test_utils/                     # shared test harness/utilities
```

### Naming conventions
- File names end with `_test.dart`
- Prefer descriptive test names:
  - `sale_access_gate_test.dart`
  - `policy_parsing_test.dart`
- Prefer `group()` by subject, not by method name.

## Utilities (standard)

### Fixtures
- Use `test/test_utils/fixture_reader.dart`:
  - `readFixture(path)`
  - `readJsonFixture(path)`
  - `readJsonMapFixture(path)`

Recommended practice:
- Store JSON under `test/fixtures/<feature>/...`
- Keep fixtures small and stable (avoid random timestamps/IDs unless the test needs them).

### Riverpod
- Use `test/test_utils/riverpod_test_utils.dart`:
  - `createTestContainer(overrides: [...])` for unit tests

For widget tests:
- Wrap widgets in a `ProviderScope(overrides: [...])` and a `MaterialApp`.
- Use the shared harness: `test/test_utils/pump_app.dart`.

## Local commands
- `flutter analyze`
- `flutter test`

## Data layer testing
See `handbook/quality/data_layer_testing.md` for auth/data-layer focused unit-test notes and patterns.

## Notes (browser-first, mobile later)
- For now we prioritize unit/widget tests because the primary target is web.
- When Android/iOS/iPadOS become active targets, we add `integration_test/` as a separate milestone.
