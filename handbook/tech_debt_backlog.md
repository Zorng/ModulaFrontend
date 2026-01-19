# Tech Debt Backlog (Smells → Actions)

Goal: turn “we have smells” into a concrete, prioritized backlog that the team can execute with minimal extra explanation.

Legend:
- **P0** = blocks delivery / causes frequent regressions
- **P1** = high cost over time / slows delivery significantly
- **P2** = cleanup/consistency improvements (do opportunistically)

Rule of engagement:
- When refactoring a smell, add/adjust tests for the behavior you’re touching (see `handbook/quality/testing.md`).
- Keep refactors incremental. Prefer “strangler” migrations over big-bang rewrites.

---

## P0 — Must address soon

### TD-001 — State management inconsistency (provider patterns + async UX)

- **Status:** In progress (Phase 1 completed: hydration orchestration)
- **Symptom:** state management still relies on legacy Riverpod APIs in critical flows; patterns are inconsistent across features.
- **Why it matters:** makes hydration/error handling inconsistent and increases circular dependency risk.
- **Examples:**
  - `lib/features/auth/ui/viewmodels/login_controller.dart`
- **Common sub-smells:**
  - Side-effects triggered from provider `build()` (e.g., `Future.microtask(...)` patterns).
  - Backend calls executed without `AsyncValue`/loading state, resulting in “frozen” UI.
- **Progress so far:**
  - Removed provider-build side effects for policy + cash session (no `Future.microtask(load)` in their `build()`).
  - Centralized auth/tenant/branch hydration via `lib/core/hydration/app_hydration_listener.dart` (login/logout/branch switch now triggers policy + cash session reload consistently).
  - Added widget coverage for hydration behavior: `test/core/hydration/app_hydration_listener_test.dart`.
  - Fixed hydration listener implementation to use `ref.listenManual` (safe outside build) and defer initial session sync until after first frame (avoids Riverpod lifecycle mutation assertions).
- **Proposed remediation:**
  - Migrate to `Notifier`/`AsyncNotifier` patterns per `handbook/non_negotiables.md`.
  - Keep the public API stable (UI shouldn’t change more than necessary).
- **Suggested tests:**
  - Login/logout cycles do not regress (unit tests around session context + “hydration triggers”).

### TD-002 — Data layer leaks raw JSON/maps and “dynamic” types

- **Status:** In progress (Reporting module migrated; Sale/Cash session pending)
- **Symptom:** repositories/APIs return `Map<String, dynamic>` / `List<Map<String, dynamic>>` instead of domain models; UI/viewmodels often must interpret payloads.
- **Why it matters:** API contract changes silently break runtime behavior; hard to test; encourages duplication.
- **Examples:**
  - `lib/features/sale/data/sale_api.dart`
  - `lib/features/sale/data/sale_repository.dart`
  - `lib/features/cash_session/data/cash_session_api.dart`
  - `lib/features/cash_session/data/cash_session_repository.dart`
  - `lib/features/menu/data/menu_api.dart`
  - `lib/features/menu/data/menu_repository.dart`
  - `lib/features/reporting/data/reporting_api.dart`
  - `lib/features/reporting/data/reporting_repository.dart`
- **Proposed remediation:**
  - Introduce DTOs in `data/dto/` and domain models in `domain/models/`.
  - Repositories return **domain models only**.
  - Keep API parsing localized to API/DTO layer.
- **Progress so far:**
  - Reporting now returns typed DTO/domain models (no raw `Map` escapes):
    - `lib/features/reporting/data/dto/…`
    - `lib/features/reporting/domain/models/…`
    - `lib/features/reporting/data/reporting_api.dart`
    - `lib/features/reporting/data/reporting_repository.dart`
  - X/Z report viewmodels no longer parse JSON maps:
    - `lib/features/cash_session/ui/viewmodels/x_report_viewmodel.dart`
    - `lib/features/cash_session/ui/viewmodels/z_report_viewmodel.dart`
  - Added fixture-based unit tests:
    - `test/reporting/reporting_mapping_test.dart`
- **Suggested tests:**
  - Parsing/mapping unit tests per endpoint payload (fixture-based).

### TD-003 — Navigation is inconsistent (go_router vs Navigator.push)

- **Status:** Completed
- **Symptom:** pages are pushed using `Navigator.push` in many places instead of the declared routing system.
- **Why it matters:** back-stack inconsistencies, “no page found” surprises, and inconsistent deep-link behavior.
- **Examples (non-exhaustive):**
  - `lib/features/auth/ui/portals/admin_portal.dart`
  - `lib/features/auth/ui/portals/cashier_portal.dart`
  - `lib/features/menu/ui/view/menu_page.dart`
  - `lib/features/menu/ui/view/modifiers_management_page.dart`
  - `lib/features/policy/ui/view/policy_page.dart`
  - `lib/features/sale/ui/view/sale_page.dart`
  - `lib/features/sale/ui/view/sale_cart_page.dart`
- **Proposed remediation:**
  - Standardize page navigation through the routing layer (`go_router`).
  - Allow `Navigator` only for true modal flows if needed (document exceptions).
- **Suggested tests:**
  - Widget tests: verify key routes render and back navigation works for a few critical flows.
  - Completed: replaced all `Navigator.push(...)` / `Navigator.of(context).push(...)` page navigation with `go_router` routes; modals still use `Navigator.pop(...)` where appropriate.

### TD-004 — Auth context changes are not orchestrated via a single “hydration” flow

- **Status:** Completed (AppHydrationListener)
- **Symptom:** login/logout/tenant selection/branch switching trigger multiple side effects in an ad-hoc way.
- **Why it matters:** “works on first login only”, stale policies/cash session state, circular dependency errors.
- **Examples:**
  - `lib/features/auth/ui/viewmodels/login_controller.dart`
  - `lib/features/policy/ui/viewmodels/policy_viewmodel.dart` (auto-load behavior inside `build`)
  - `lib/features/auth/domain/auth_branch_provider.dart`
- **Proposed remediation:**
  - Define and implement a single hydration sequence:
    - set auth token/tenant
    - resolve active branch
    - refresh branch-scoped state (policy, cash session, etc.)
  - Avoid triggering network loads from provider `build()` where possible; prefer explicit `load()/refresh()`.
- **Suggested tests:**
  - Unit tests: “second login” still hydrates; tenant selection hydrates; logout resets without exceptions.
  - Completed: `lib/core/hydration/app_hydration_listener.dart` orchestrates token/tenant/branch changes and refreshes branch-scoped state (policy + cash session) without provider-build side effects; covered by `test/core/hydration/app_hydration_listener_test.dart`.

---

## P1 — High ROI cleanups (schedule after P0)

### TD-101 — Widget bloat (very large files / deep widget trees)

- **Status:** In progress (page debloat largely done; dedupe/promote candidates ongoing)
- **Symptom:** pages and repositories exceed ~500 LOC and mix concerns; hard to review and causes merge conflicts.
- **Examples (largest files):**
  - `lib/features/sale/ui/view/sale_cart_page.dart`
  - `lib/features/inventory/ui/view/restock_stock_item_page.dart`
  - `lib/features/inventory/ui/view/stock_item_detail_page.dart`
  - `lib/features/inventory/ui/view/add_stock_item_page.dart`
  - `lib/features/menu/ui/view/menu_item_form_page.dart`
  - `lib/features/staff_attendance/ui/view/attendance_page.dart`
  - `lib/features/auth/ui/portals/admin_portal.dart`
- **Proposed remediation:**
  - Enforce screen composition rule: extract sections to `ui/widgets/` (feature) or `lib/core/widgets/` (shared).
  - Keep page files focused on composition + wiring.
  - Track extracted widgets and promotion candidates in `refactorPlan/debloat_refactor_tracking.md`.
- **Suggested tests:**
  - Widget tests on extracted widgets are optional, but keep/extend the screen-level tests for critical states.

### TD-102 — Silent error swallowing (`catch (_) {}`) hides failures

- **Symptom:** failures are ignored, leaving UI in inconsistent state without explaining why.
- **Examples:**
  - `lib/features/menu/data/menu_repository.dart` (multiple `catch (_) {}`)
  - `lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart` (remote update failures swallowed)
  - `lib/features/auth/ui/viewmodels/login_controller.dart` (invalidate failure swallowed)
- **Proposed remediation:**
  - Replace silent catches with:
    - logged errors (debug)
    - surfaced user-safe errors when appropriate
    - retry/backoff where appropriate
- **Suggested tests:**
  - Unit tests around failure modes for critical workflows (e.g., update quantity/remove item).

### TD-103 — Debug prints leak into runtime behavior

- **Symptom:** `print(...)` exists in production paths.
- **Examples:**
  - `lib/features/auth/ui/viewmodels/login_controller.dart`
  - `lib/features/staff/ui/view/staff_form_view.dart`
- **Proposed remediation:**
  - Use a logger abstraction (or guarded debug logging) and keep UI user-safe (see `handbook/quality/error_handling.md`).

### TD-104 — Mock/dead code paths in core repositories

- **Symptom:** toggles / TODOs exist that make it unclear what source-of-truth is.
- **Examples:**
  - `lib/features/auth/data/auth_repository.dart` (`_useMockRepository`)
  - `lib/features/inventory/data/stock_item_api.dart` (mock data embedded in API layer)
  - `lib/features/menu/data/menu_api.dart` (`TODO` for real endpoint)
  - `lib/features/menu/data/menu_mock_data_source.dart` (still present)
- **Proposed remediation:**
  - Gate mocks behind explicit build flavors / dependency injection for tests only.
  - Remove/relocate demo mock data so production path is unambiguous.

---

## P2 — Opportunistic improvements

### TD-201 — Consistent async UX (no “freeze”)

- **Symptom:** some actions run network calls without visible loading/disabled state, causing perceived freezes.
- **Examples:** varies by screen; re-validate when touching:
  - `lib/features/sale/ui/view/sale_cart_page.dart`
  - `lib/features/menu/ui/view/menu_page.dart`
  - `lib/features/inventory/ui/view/inventory_home_page.dart`
- **Proposed remediation:**
  - Standardize loading/error/empty widgets and button-disabled patterns.

### TD-202 — Standardize date/number formatting utilities

- **Symptom:** formatting logic duplicated across UI layers.
- **Proposed remediation:**
  - centralize common formatters in `lib/core/formatters/` (or similar).

---

## Tracking fields (for Jira tickets)

When you create a Jira ticket from an item above, include:
- **Priority:** P0/P1/P2
- **Touched files:** list
- **Manual QA steps:** short list
- **Test plan:** what tests you’ll add/adjust
