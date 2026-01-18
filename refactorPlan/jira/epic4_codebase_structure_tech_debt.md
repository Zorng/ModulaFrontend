# Epic 4 — Codebase Structure & Tech Debt Cleanup

## Outcome (for Jira Epic)

Make the frontend **maintainable and scalable** by improving code organization, removing recurring “smell” patterns, and standardizing how modules handle state, API mapping, navigation, and UI composition—so the team can deliver features with less breakage and less manual debugging.

## Why

- The project has accumulated inconsistent patterns (state management, routing, API mapping, UI structure).
- Code smells increase regression risk and slow down onboarding/handover.
- Manual QA load is high because changes have unpredictable side effects.

## Scope

### In scope
- A documented, agreed **frontend structure** (where things live and why).
- A prioritized **smell/tech-debt backlog** with file references.
- Incremental refactors that reduce duplication and circular dependencies (esp. Riverpod provider cycles).
- Standardized patterns:
  - API → DTO → Domain mapping
  - ViewModel/Controller responsibilities vs UI responsibilities
  - Error/loading/empty handling
  - Routing conventions (`go_router` vs ad-hoc `Navigator.push`)
  - “Hydration” points (login, tenant switch, branch switch)

### Out of scope
- New feature delivery not needed for cleanup.
- Printing (Epic 5), responsive work (Epic 1), navigation IA work (Epic 2), testing strategy (Epic 3).

### Notes / Constraints
- Multiple `Scaffold`s is normal in Flutter and **not** a smell by itself.
- Refactors should be incremental and scoped to avoid destabilizing the app.

---

## Jira Issues (Draft — copy/paste ready)

### EPIC — `[Tech Debt] Standardize frontend structure and remove high-risk smells`

- **Goal:** Reduce regressions and improve maintainability by standardizing patterns and paying down the highest-impact tech debt.

---

### Story 4.1 — `[Architecture] Document frontend structure and coding conventions`

- **Goal:** New contributors can understand where to put code and how the app is structured without tribal knowledge.
- **Scope:** Repo-level documentation.
- **AC:**
  - Doc describes the folder/module structure, with examples (domain/data/ui/viewmodels).
  - Doc includes “where should this code go?” guidance and anti-patterns to avoid.
  - Doc includes routing/state conventions used in this repo.
- **Tasks:**
  - Write `docs/frontend_architecture.md` (or update existing docs if present).
  - Add a short “common patterns” section (fetch + map + state + render).

---

### Story 4.2 — `[Tech Debt] Create smell backlog with file references and priority`

- **Goal:** Convert “we have smells” into a concrete prioritized backlog.
- **AC:**
  - Smell list includes: symptom, impact, example file(s), and proposed remediation.
  - Top 10 smells are prioritized (P0/P1/P2).
- **Tasks:**
  - Create `docs/tech_debt_backlog.md` with categories:
    - State management inconsistency
    - Circular provider dependencies
    - Mixed concerns in UI
    - Inconsistent routing patterns
    - Duplicate mapping/formatting logic
    - Hardcoded values that should be data-driven

---

### Story 4.3 — `[State] Remove circular dependencies in providers (Riverpod)`

- **Goal:** Prevent runtime circular dependency errors and make state hydration reliable.
- **AC:**
  - No `CircularDependencyError` on hot restart or login/logout cycles.
  - Providers do not depend on themselves indirectly (document the fixed chains).
- **Tasks:**
  - Identify circular chains via logs and map them in a short doc section.
  - Refactor dependencies to flow one-way (e.g., auth → branch → policy; avoid policy → auth → policy).

---

### Story 4.4 — `[Routing] Standardize navigation approach and remove ad-hoc routing`

- **Goal:** Predictable navigation behavior and fewer “no page found” / back-stack surprises.
- **AC:**
  - Navigation uses `go_router` consistently for cross-feature routes.
  - `Navigator.push` is only used for local, truly modal flows (if allowed by convention).
- **Tasks:**
  - Audit remaining `Navigator.push` usage for feature navigation.
  - Replace with `go_router` where appropriate and document exceptions.

---

### Story 4.5 — `[Hydration] Standardize app load-up + context change hydration`

- **Goal:** When auth context changes, required app state reloads predictably.
- **Scope:** Login, logout, tenant change, branch change.
- **AC:**
  - On login: required state is hydrated exactly once and errors are surfaced clearly.
  - On logout: state is reset without circular dependency errors.
  - On tenant/branch switch: branch-scoped state reloads (policy, cash session, etc.).
- **Tasks:**
  - Define the hydration sequence as a short flow doc.
  - Centralize orchestration in a single controller/service if currently scattered.

---

### Story 4.6 — `[UI] Standardize loading/empty/error UI patterns`

- **Goal:** Users see consistent feedback and developers implement states quickly.
- **AC:**
  - Each list page supports: loading, empty, error, and retry.
  - Error messaging uses a consistent component (snackbar/dialog) per guideline.
- **Tasks:**
  - Define a small set of reusable widgets/patterns (e.g., `AppAsyncStateView`).
  - Apply to one pilot module, then roll out opportunistically.

---

### Story 4.7 — `[Data] Standardize DTO/domain models and mapping boundaries`

- **Goal:** Avoid “Map<String,dynamic> creeping into UI” and prevent mismatched fields.
- **AC:**
  - API parsing is isolated to data layer.
  - UI consumes typed domain models.
- **Tasks:**
  - Identify screens currently reading raw JSON/maps.
  - Add/adjust DTOs and mapping functions.

---

### Story 4.8 — `[Cleanup] Track and reduce `flutter analyze` warnings in touched areas`

- **Goal:** Stop adding new lint debt and gradually reduce existing warnings.
- **AC:**
  - Any file touched in this epic does not introduce new analyzer warnings.
  - High-signal warnings are fixed when encountered (unused imports, async context usage, deprecated APIs).
- **Tasks:**
  - Adopt a rule: “leave it better than you found it” (only for touched files).

