# Handbook Setup — Decision Log & Agenda

Goal: set up a small, maintainable documentation set that guides **teammates + AI agents**.

## Repo Documentation Split (Decision)
- Decision: create `handbook/` at repo root for workflow/engineering docs.
- Keep `docs/` for product/spec artifacts (modspecs, API contracts, schemas, etc.).

## Agenda (go one-by-one)

### 1) Handbook structure (file/folder layout)
- Status: decided (Option B)
- Options:
  - Keep `docs/` as-is for now; start `handbook/` clean.
  - Do a cleanup pass of `docs/` into subfolders later.
- Output: agreed `handbook/` tree + what each doc covers (no writing yet).

### 2) GitHub workflow upgrades (replace manual merges)
- Status: locked (CI enabled)
- Candidate changes:
  - Protect `main` (PR required; no direct pushes)
  - Squash merge
  - Require 1 reviewer
  - PR template (modspec link, Jira key, manual test steps)
  - Optional later: CI checks (`flutter analyze`, `flutter test`)
- Output: agreed minimal rules + rollout steps.

### 3) “Non‑negotiables” (top 5–10 rules)
- Status: decision locked (state ownership model); non-negotiables pending
- Decision: Frontend state & feature structure
  - We do **not** enforce “1 viewmodel = 1 screen”.
  - We adopt **State Owner + optional Screen Controller**:
    - **State Owner (Store)**: single source of truth for feature/domain state (cache + mutations), shared across screens.
    - **Screen Controller (optional)**: screen-only state (filters, tabs, pagination cursors, UI toggles), never the canonical data source.
  - Data flow is one-directional: `UI → Controller/Store → Repository → API → DTO → Domain`.
  - Feature folder convention: `domain/`, `data/`, `ui/view`, `ui/widgets`, `ui/viewmodels` (store + controllers).
  - Globals are limited to auth/tenant/branch/session (kept in `core/` or a clearly named global feature); everything else is feature-scoped.
  - Cross-feature rule: no importing another feature’s `ui/` from outside; only `domain/` and `data/` via a small “public export” entrypoint.
  - Async rule (source-of-truth):
    - Use **sync notifiers** (e.g., `Notifier<State>`) for state that does **not** require backend as source-of-truth (pure UI/local state).
    - Use **async state** (e.g., `AsyncValue<T>` via `AsyncNotifier`/`FutureProvider`) for any state that *depends on backend truth* (load/refresh/error must be representable in UI).
  - Data layer boundaries:
    - **API layer** (`data/api/…`) owns HTTP details and parses **DTOs** (request/response) from/to JSON.
    - **DTOs** live under `data/dto/…` and mirror backend payload shapes.
    - **Repository layer** (`data/repository/…`) is the only place that maps **DTOs → domain models**, aggregates/caches, and returns **domain models** upward.
    - **Domain models** live under `domain/models/…` and are used above the data layer.
    - Non-negotiable implications:
      - Repositories return **domain models only** (never DTOs).
      - API returns **DTOs only** (never domain models).
      - UI/viewmodels never import DTOs.
  - Testing requirements & guidelines (to be documented in `handbook/quality/testing.md`):
    - CI gate: PRs must pass `flutter analyze` and `flutter test` before merge.
    - Minimum expectations:
      - Bug fixes must include a regression test (unit/widget) when feasible.
      - New behavior/use cases must include at least one test proving the behavior (prefer unit; widget when UI logic is involved).
      - Pure UI layout/styling changes may omit tests, but must include screenshots + manual test steps in PR.
      - Refactors may omit new tests only if existing tests cover the touched behavior; otherwise add at least one.
    - Exception policy:
      - If no test is added, PR must include a brief reason and (when relevant) a follow-up Jira ticket to add coverage.
  - Widget reuse & bloat control (to be documented in `handbook/architecture/widgets.md`):
    - Reuse-first: check existing shared/feature widgets before creating new ones.
    - Shared vs feature-local:
      - Used in 2+ features → move to `lib/core/widgets/`.
      - Used only in one feature → keep in `lib/features/<feature>/ui/widgets/`.
    - File size hygiene (guideline, not hard failure): screens should be kept small; when a screen grows large, extract meaningful sections.
    - Screen composition (practical rule):
      - A screen/page file should not declare large custom widget classes.
      - Small private helpers are allowed; at most one small private widget is allowed if it stays trivial (≈ ≤30 LOC).
      - Anything substantial must be extracted into feature widgets or shared widgets.
    - Parallel development policy for shared widgets:
      - Prefer **shared-first** for obvious primitives (buttons/cards/empty states/key-value rows) when coordination is feasible.
      - Temporary duplication is allowed when coordination is hard or requirements are still evolving, but must be:
        - kept minimal, and
        - tracked with a follow-up Jira ticket to dedupe/promote to `lib/core/widgets/`.
      - “Promote later” is acceptable: implement as feature-local first, then move to shared once a second feature needs it.
    - Common widgets categorization:
      - Shared widgets under `lib/core/widgets/` should be categorized by UI role to avoid a “junk drawer”:
        - `layout/`, `navigation/`, `forms/`, `feedback/`, `display/`, `buttons/`, `media/` (as needed)
      - A widget becomes “core” only when used in 2+ features; otherwise keep it feature-local.
  - Navigation & routing rules (to be documented in `handbook/architecture/navigation.md`):
    - Single route registry:
      - All pages are registered via `GoRoute` in the app router (`appRouterProvider` in `lib/app.dart`).
      - Route paths/names come from `AppRoute` (`lib/core/routing/app_router.dart`); avoid hardcoded route strings in UI.
    - `go_router` for pages:
      - New page navigation must use `context.go(...)` / `context.push(...)`.
      - Do not use `Navigator.of(context).push(...)` for page navigation.
      - `Navigator.pop(...)` is allowed for dialogs/modals and returning selection results.
    - Route stacking:
      - Use `context.go(...)` for “switch destination/home/portal/tab” (replace stack).
      - Use `context.push(...)` for details/sub-pages (add to stack).
    - Route params:
      - Prefer passing **IDs** in route params/query over passing full objects via `state.extra` (exceptions allowed for short-lived flows).
  - Error handling & UX (to be documented in `handbook/quality/error_handling.md`):
    - No raw technical errors in production UI:
      - Do not show raw `DioException`, stack traces, or network-layer messages to end users in release builds.
      - Default user-safe message: "Oops, something went wrong."
      - Show a retry action when safe/possible.
    - Debug vs release behavior:
      - In debug/developer mode, it is acceptable to show technical details (e.g., expandable “Details” section) to speed up development.
      - In release/production mode, UI must show only user-safe messages; technical details go to logs/crash reporting.
      - Developer error visibility should be configurable through `.env` (e.g., `SHOW_DEBUG_ERRORS=true|false`).
    - Backend calls must surface progress:
      - Any backend call must have explicit loading state in UI (no “freeze until complete”).
    - Prefer consistent error states:
      - Use shared error/loading/empty widgets (or consistent patterns) rather than ad-hoc snackbars per screen.
  - Provider conventions (to be documented in `handbook/architecture/providers.md`):
    - Provider type defaults:
      - Use `NotifierProvider`/`Notifier` for local/UI truth.
      - Use async state (`AsyncValue<T>` via `AsyncNotifierProvider`/`AsyncNotifier`) for backend source-of-truth state.
      - Use `Provider` for dependencies (API clients, repositories).
      - Do not introduce new legacy `StateNotifierProvider`/`StateNotifier`.
      - `StateProvider` is allowed only for trivial UI toggles; otherwise prefer a screen controller.
    - Backend data loading style:
      - Prefer explicit `load()/refresh()` methods (triggered from UI/controller) over implicit auto-fetch in provider constructors/build.
    - Naming/placement:
      - Providers end with `Provider` and live near what they provide (feature viewmodels in `ui/viewmodels`, repos/APIs in `data/…`).
    - `ref.watch` vs `ref.read`:
      - UI uses `watch` for rendering and `read` in event handlers.
      - Notifiers use `watch` for stable dependencies and `read` inside actions to reduce circular dependencies.
- Output: short list of enforceable non-negotiables (team + agents), plus examples (next).
  - Status update: `handbook/non_negotiables.md` created (initial draft); details will be expanded in linked handbook docs.

### 4) Agent guide scope
- Status: locked
- Decision:
  - Create an agent-facing guide that defines required reads, preflight checks, and validation.
  - Source: `handbook/agents/agent_guide.md`
  - Repo root `AGENTS.md` points to the handbook guide.
- Output: what an agent must read/do before changes (commands, file entry points, validation).

### 5) `docs/` cleanup (optional, later)
- Status: pending
- Output: whether/when to reorganize `docs/`, and target structure.

## Notes
- Keep scope small: prefer a few strong rules over many weak ones.
- Make docs actionable: templates/checklists/examples > essays.
