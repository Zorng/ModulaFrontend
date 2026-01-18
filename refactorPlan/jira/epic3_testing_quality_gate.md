# Epic 3 — Testing & Quality Gate

## Outcome (for Jira Epic)

Establish a reliable testing baseline (unit + widget + integration) and a lightweight quality gate so changes stop breaking unrelated features and the team spends less time on manual prompting/debugging.

## Why

- Regressions are frequent because changes are not protected by automated tests.
- Manual testing is slow and inconsistent, especially with multi-module flows (auth → cash session → sale → reports).
- Some existing tests are outdated and no longer represent the current modspec/contracts.

## Scope

### In scope
- Define a pragmatic test pyramid and conventions for this repo.
- Add test utilities (fixtures, fake clients, provider overrides).
- Create a minimal but high-impact suite:
  - Unit tests for parsing/mapping and business logic.
  - Widget tests for critical screens/guards.
  - Integration tests for the main user journeys.
- Add a quality gate: `flutter analyze` + tests in CI (or a documented pre-merge checklist if CI is not ready).

### Out of scope
- Full coverage of every screen.
- Large refactors that are not required to make code testable (belongs to Epic 4).

---

## Jira Issues (Draft — copy/paste ready)

### EPIC — `[Testing] Establish test baseline and quality gate`

- **Goal:** Prevent regressions and reduce manual verification cost.

---

### Story 3.1 — `[Testing] Define test strategy, conventions, and how-to-run docs`

- **Goal:** The team can write and run tests consistently.
- **AC:**
  - `docs/TESTING.md` exists and covers: unit/widget/integration test commands and patterns.
  - Clear guidance on: where to put tests, naming conventions, fixtures, and mocking approach.
- **Tasks:**
  - Document recommended pyramid: Unit (many) / Widget (some) / Integration (few).
  - Document standard “Arrange/Act/Assert” style and fixture usage.

---

### Story 3.2 — `[Testing] Build reusable test utilities (fixtures + providers + fakes)`

- **Goal:** Writing tests is fast and does not require re-implementing mocks.
- **AC:**
  - Fixture reader exists and is used by tests.
  - Provider override helpers exist for Riverpod.
  - Network calls can be mocked deterministically (Dio adapter or repository fakes).
- **Tasks:**
  - Add/standardize `test/test_utils/*` helpers.
  - Decide mocking boundary: prefer repository-level fakes for unit/widget tests; Dio adapter for API parsing tests.

---

### Story 3.3 — `[Testing] Replace/retire outdated tests that no longer match current modspec`

- **Goal:** Tests reflect reality and don’t create noise.
- **AC:**
  - Outdated tests are either updated to the current contracts or removed with justification in the PR.
  - Test suite passes reliably after updates.
- **Tasks:**
  - Audit `test/auth/*` and other legacy tests; tag as Update/Remove.
  - Update parsing tests to match current `docs/apiContracts/auth.md` and tenant/branch session shape.

---

### Story 3.4 — `[Testing][Unit] Add high-value unit tests for mapping and calculations`

- **Goal:** Catch breaking API/contract changes early.
- **AC:** Unit tests exist for:
  - Auth session parsing (tenant + branch context, headers like `X-Tenant-Id`)
  - Policy parsing + updating (ensures requests are sent, responses mapped)
  - Cash session “active session” response handling (including 404 = no active session)
  - Inventory journal parsing (including `occurredAt` vs `createdAt`)
- **QA:** Run unit tests; tests pass.

---

### Story 3.5 — `[Testing][Widget] Add widget tests for critical UX guards and navigation`

- **Goal:** Prevent regressions in the highest-risk UI behaviors.
- **AC:** Widget tests cover:
  - Login → tenant selection (multi-tenant user) flow renders correctly
  - Sale item detail: “Add item” is disabled when no active cash session
  - X report page shows empty state + updates when filter changes
- **QA:** Run widget tests; tests pass.

---

### Story 3.6 — `[Testing][Integration] Add end-to-end tests for core flows`

- **Goal:** Validate critical flows with real navigation and state wiring.
- **AC:** Integration tests cover:
  - Login → open cash session → sale → checkout
  - Inventory restock → inventory on-hand refresh
  - X report refresh after multiple sales
- **Notes:** Integration tests can run against mock/stubbed backends where needed.

---

### Story 3.7 — `[Quality Gate] Add CI (or pre-merge gate) for analyze + tests`

- **Goal:** Stop merging changes that obviously break the app.
- **AC:**
  - `flutter analyze` runs and must pass (or only known exceptions are explicitly allowed).
  - Tests run (unit + widget at minimum).
- **Tasks:**
  - Add a CI workflow (GitHub Actions or equivalent) OR document required local commands if CI is not available yet.

---

### Story 3.8 — `[Testing] Define “minimum test requirement” per PR`

- **Goal:** Keep testing sustainable without blocking delivery.
- **AC:**
  - Simple rule documented (e.g., any contract/mapping change requires unit test; any new UI guard requires widget test).
  - Review checklist exists and is used.

