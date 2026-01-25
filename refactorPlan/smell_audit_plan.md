# Smell Audit & Cleanup Plan (Frontend)

Goal: Identify and fix code smells that hurt readability, scalability, and maintainability before handoff.

## Scope
- Primary: `lib/`
- Secondary: docs only after smells/dead code are resolved

## Principles
- Minimal behavior change unless explicitly requested.
- Fix patterns once, then roll out consistently.
- Track every change with a decision or TODO if deferred.

---

## Phase 0 — Prep & Baseline
- [x] Confirm scope & priorities with owner
- [x] Define smell categories & severity rubric
- [x] Capture baseline (rg scan + size scan; analyze deferred by repo constraints)

## Phase 1 — Smell Inventory (Discovery)
- [ ] Create/maintain `smell_audit_log.md` with:
  - file
  - smell category
  - severity (P0/P1/P2)
  - recommended fix
  - owner/ETA

### Categories
- Architecture & navigation
- State management (AsyncValue misuse, sync state for async ops)
- Widget bloat / duplication
- Data-layer boundary violations (DTO leakage)
- Error handling / loading UX
- Routing / path inconsistencies
- Testability gaps (missing keys, no DI seams)
- Lint hygiene

## Phase 2 — Prioritized Fix Plan
- [x] Group issues into refactor batches (by feature / shared layer)
- [x] Define “stop-the-line” rules (new PRs must not add smells)

## Phase 3 — Remediation (Iterative)
- [ ] Fix P0s first
- [ ] Fix P1s (batch by feature)
- [ ] Fix P2s (opportunistic)
- [ ] Update doc standards after smells/dead code are resolved

## Phase 4 — Verification
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Manual smoke (portal → sale/menu/inventory)

## Phase 5 — Handoff
- [ ] Summarize key refactors
- [ ] Update onboarding/handbook pointers

---

## Progress Log
- 2026-01-25: Plan created
- 2026-01-25: Scope locked to `lib/`; docs deferred until cleanup complete

## Severity Rubric
- **P0**: Breaks core flows, causes runtime errors, or blocks dev velocity.
- **P1**: High-risk maintainability issues (duplication, inconsistent patterns, fragile coupling).
- **P2**: Minor hygiene issues (naming, small lint warnings, minor UX inconsistency).

## Known Antipatterns to Scan
- DTOs imported into UI/viewmodels
- Async work handled in sync Notifiers
- Direct Navigator usage instead of go_router
- Large widget files (>400 LOC) without extraction
- Duplicated UI components across features
- Hardcoded routes/paths
- Missing loading/error UI
- Mock data embedded in API/repo
- Unused routes/dangling feature cards

## Phase 2 — Prioritized Fix Plan (Batching)

### Batch A — Routing Hygiene (P2 → quick wins)
- Replace Navigator.pop with context.pop in listed UI files (SA-008…SA-023)

### Batch B — Widget Bloat (P1 → UI pages)
- Stock Item Detail page extraction (SA-003)
- Add Stock Item page extraction (SA-004)
- Sale cart content extraction (SA-007)

### Batch C — Data Layer Size & Separation (P1)
- Split `menu_repository.dart` mapping helpers (SA-002)
- Split `menu_api.dart` request helpers (SA-005)

### Batch D — State Management Size (P1)
- Break down `sale_cart_viewmodel.dart` (SA-006)

### Batch E — Mock Data Smell (P1)
- Move mock data from `stock_item_api.dart` (SA-024)

### Batch F — App Route Composition (P1)
- Split `lib/app.dart` route definitions (SA-001)

### Stop-the-line Rules (effective immediately)
- No new `Navigator.*` in UI; use go_router + modal helpers
- New UI screens must include loading/error UX for async ops
- No DTO imports in UI/viewmodels
