# Frontend Testing Setup Plan (Unit + Widget + Integration)

**Goal:** Replace legacy/irrelevant tests with **ModSpec + API-contract driven** tests, and add coverage for the most critical cross-module flows (Auth → Tenant selection → Policy → Cash Session → Sale).

**Scope (initial):**
- Update existing `test/auth/*` to match current `docs/apiContracts/auth.md` + tenant-aware session model.
- Add unit/widget tests for **Sale ↔ Cash Session** gating (policy-driven read-only sale).
- Add parsing tests for **Policy bundle** (cash-session policies).
- Add a minimal integration test harness (optional, depends on environment).

**References**
- ModSpec: `docs/modSpec/sale_module.md`, `docs/modSpec/cashSession_module.md`, `docs/modSpec/policy_module.md`
- API contracts: `docs/apiContracts/auth.md`, `docs/apiContracts/tenant.md`
- Gate implementation: `lib/features/sale/ui/viewmodels/sale_access_gate.dart`

---

## 1) Testing Philosophy (for this repo)

### 1.1 Pyramid
1) **Unit tests (fast, deterministic)**  
   - JSON parsing + model mapping  
   - ViewModel/domain logic with mocked repositories  
2) **Widget tests (UI behavior)**  
   - Read-only vs enabled UI states  
   - Role-aware navigation CTA behavior  
3) **Integration tests (end-to-end)**  
   - Minimal “happy path” flows against real backend or a controlled stub

### 1.2 ModSpec-driven definition of “correct”
- Tests should directly encode **ModSpec rules** (e.g., “browse allowed; draft creation blocked unless cash session active when policy requires it”).
- Contract parsing tests should encode **current API contracts** (fixtures updated when contracts change).

---

## 2) Constraints / Environment Notes

- `flutter analyze` may fail in the sandbox (Flutter SDK cache write). Prefer `dart analyze` in CI/sandbox; run `flutter test` locally when needed.
- Network is restricted; do not introduce dependencies that require pub downloads unless already present in `pubspec.yaml`.
- Existing dev deps: `flutter_test`, `mocktail`.

---

## 3) Directory Structure (target)

```text
test/
  fixtures/
    auth/
    policy/
    sale/
  auth/
  policy/
  cash_session/
  sale/
  routing/
integration_test/            # optional (Flutter integration tests)
```

---

## 4) Fixtures Strategy (API-contract regression)

### Rules
- Store backend samples as JSON fixtures under `test/fixtures/**`.
- Keep fixtures minimal but complete enough to parse into domain models.
- Fixtures are owned by contracts: when `docs/apiContracts/*.md` changes, update fixtures first, then fix parsing.

### Planned fixtures
- `test/fixtures/auth/login_single_tenant.json`
- `test/fixtures/auth/login_multi_tenant.json`
- `test/fixtures/policy/policy_bundle.json` (must include cash-session policies used by Sale)

---

## 5) Unit Test Plan (by module)

### 5.1 Auth (replace legacy parsing tests)
- Update `test/auth/auth_api_parsing_test.dart` to match current login response contract.
- Keep/adjust `test/auth/auth_session_snapshot_test.dart` for round-trip:
  - `AuthSession.toJson()` → `AuthSession.fromJson()`
  - Ensure memberships + branches + selected tenant context round-trip

### 5.2 Policy
- Add `test/policy/policy_parsing_test.dart`
  - Ensures `cashRequireSessionForSales` is parsed and defaulted correctly.

### 5.3 Sale (gate + draft creation guard)
- Add `test/sale/sale_access_gate_test.dart`
  - requires session + no session → `canCreateDraftSale=false`
  - requires session + open session → `true`
  - does not require session → `true` even if no session
- Add `test/sale/sale_cart_notifier_guard_test.dart`
  - when blocked, `addSelection()` does **not** call `ensureDraft()` / **does not** hit repository methods
  - when allowed, repository methods are invoked

### 5.4 Routing (role-aware cash session CTA)
- Add `test/routing/cash_session_route_test.dart`
  - Admin role maps to `/portal/admin/session`
  - Cashier role maps to `/portal/cashier/session`

---

## 6) Widget Test Plan (read-only UX)

### Target behaviors (from ModSpec)
- Sale page is browsable without session.
- When policy requires session and session is inactive:
  - “Add Item” disabled in item detail
  - Cart controls/checkout disabled
  - CTA exists to go to cash session

### Planned widget tests
- `test/sale/sale_page_readonly_test.dart`
- `test/sale/sale_item_detail_readonly_test.dart`
- `test/sale/sale_cart_readonly_test.dart`

### Technique
- Override `saleAccessGateProvider` with a fixed `SaleAccessGate` value to avoid coupling widget tests to network/policy loading.

---

## 7) Integration Test Plan (optional but recommended)

### Option A — Real backend (highest confidence)
- Requires seeded backend + stable test tenant/user.
- Flows:
  - Multi-tenant login → tenant selection → portal
  - Policy requires session → sale blocked → open session → sale enabled → checkout

### Option B — Local stub server (no backend dependency)
- Use a lightweight stub (if feasible later) to serve fixed JSON to Dio.
- Good for deterministic CI, but more work.

---

## 8) Implementation Checklist (track progress)

### Phase 0 — Test scaffolding
- [x] Create `test/fixtures/**` folders + initial fixtures
- [x] Add small test helpers (fixture loader, provider overrides)

### Phase 1 — Auth tests update
- [x] Rewrite `test/auth/auth_api_parsing_test.dart` for latest contract
- [x] Update `test/auth/auth_session_snapshot_test.dart` for latest session model

### Phase 2 — Policy parsing tests
- [x] Add `test/policy/policy_parsing_test.dart`

### Phase 3 — Sale gate + viewmodel guard unit tests
- [x] Add `test/sale/sale_access_gate_test.dart`
- [x] Add `test/sale/sale_cart_notifier_guard_test.dart`

### Phase 4 — Widget tests (read-only UX)
- [x] Add Sale page read-only widget test
- [x] Add Sale item detail read-only widget test
- [x] Add Cart read-only widget test

### Phase 5 — Integration tests (optional)
- [ ] Add `integration_test/` scaffold
- [ ] Add 1 happy-path integration test for sale gating

### Phase 6 — Maintenance / CI
- [ ] Document how to run tests locally (`dart test`, `flutter test`)
- [ ] Add “update fixtures when contracts change” note to `docs/modSpecFrontend/frontend_guide.md` (optional)

---

## 9) Progress Log

- 2025-12-22: Created testing setup plan.
- 2025-12-22: Phase 0 completed (fixtures + test utilities scaffold).
- 2025-12-22: Phase 1 completed (auth login parsing + session snapshot tests updated to fixtures/contract).
- 2025-12-22: Phase 2 completed (policy parsing tests for cash-session gating + FX rate).
- 2025-12-22: Phase 3 completed (sale access gate + cart guard unit tests).
- 2025-12-22: Phase 4 completed (widget tests for read-only Sale UX).
