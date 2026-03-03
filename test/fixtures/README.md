This folder contains stable JSON fixtures used by unit/widget tests.

Conventions:
- Put payloads under `test/fixtures/<feature>/...`
- Keep fixtures small and deterministic (avoid random timestamps/UUIDs unless the test needs them)
- Load fixtures via `test/test_utils/fixture_reader.dart`
- Inventory contract fixtures live under `test/fixtures/inventory/`.
