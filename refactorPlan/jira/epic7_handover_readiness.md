# Epic 7 — Handover Readiness (Docs + Ownership + Runbook)

## Outcome (for Jira Epic)

Make the frontend project easy to take over by:
- documenting how it works,
- documenting how to run/debug/test it,
- documenting who owns what,
- and creating simple operational checklists so delivery does not depend on a single person.

## Why

- The project has grown quickly and relies on tribal knowledge.
- New teammates lose time finding patterns, fixing regressions, and guessing procedures.
- A good handover reduces risk and improves throughput.

## Scope

### In scope
- Repo documentation:
  - architecture overview (high-level)
  - runbook (how to run + debug)
  - testing procedure (links to Epic 3)
  - coding conventions (where things go)
- Ownership mapping:
  - module ownership
  - escalation contacts
  - “who approves changes” for cross-cutting areas (auth, policy, routing)
- Operational readiness:
  - PR checklist
  - release/demo checklist
  - known issues list

### Out of scope
- Implementing missing features.
- Large refactors (Epic 4).
- Widescreen implementation (Epic 1).

---

## Jira Issues (Draft — copy/paste ready)

### EPIC — `[Handover] Frontend docs, runbook, and ownership mapping`

- **Goal:** Reduce onboarding and maintenance cost by making the project self-explanatory.

---

### Story 7.1 — `[Docs] Create ownership map for modules and cross-cutting areas`

- **Goal:** Everyone knows who owns what and where to ask questions.
- **AC:**
  - Ownership map exists and is easy to find (linked from README/runbook).
  - Includes: modules, primary owner, backup owner, and escalation contact.
  - Includes cross-cutting areas: auth/tenant/branch context, policy, routing/navigation, network/Dio, printing, reporting.
- **Tasks:**
  - Create `docs/OWNERSHIP.md`.
  - Add a small “how to update ownership” note (process).

---

### Story 7.2 — `[Docs] Add project runbook (setup + common workflows)`

- **Goal:** A new dev can run the app and debug issues without direct help.
- **AC:**
  - `docs/RUNBOOK.md` exists with:
    - install/run commands
    - env/config notes (API base URL, tenant header behavior like `X-Tenant-Id`)
    - login/tenant/branch selection flow notes
    - “where to look” for common issues (401, CORS, 404, parsing mismatch)
- **QA:** A teammate follows the runbook and reaches the portal successfully.

---

### Story 7.3 — `[Docs] Document frontend architecture and conventions`

- **Goal:** New contributors understand structure and patterns.
- **AC:**
  - Architecture doc exists (module breakdown: domain/data/ui/viewmodels).
  - Conventions include:
    - where models live
    - where API mapping happens
    - how Riverpod providers should be organized
    - routing convention (`go_router` patterns)
- **Tasks:**
  - Create `docs/frontend_architecture.md` (or consolidate into existing doc if preferred).

---

### Story 7.4 — `[Docs] Add testing procedure and link to Epic 3 artifacts`

- **Goal:** Handover includes how to validate changes.
- **AC:**
  - `docs/TESTING.md` exists (or links to it) and includes unit/widget/integration commands.
  - Links to test utilities/fixtures conventions.
- **Dependencies:** Epic 3 Story 3.1.

---

### Story 7.5 — `[Process] Add PR checklist (quality gate without CI dependency)`

- **Goal:** Improve consistency even before CI is fully enforced.
- **AC:**
  - PR checklist exists (template or doc) requiring:
    - `flutter analyze`
    - relevant tests (at least unit/widget for touched areas)
    - screenshots for UI changes (mobile + wide if applicable)
    - brief risk assessment (“what could break”)
- **Tasks:**
  - Create `.github/pull_request_template.md` (if repo uses GitHub) or `docs/PR_CHECKLIST.md`.

---

### Story 7.6 — `[Process] Add release/demo checklist`

- **Goal:** Demo/release is repeatable and less error-prone.
- **AC:**
  - Checklist includes:
    - clean start instructions (hot restart notes)
    - basic smoke flows (login → sale → cash session → report)
    - print test (if available)
    - known temporary “coming soon” areas
- **Tasks:**
  - Create `docs/RELEASE_CHECKLIST.md`.

---

### Story 7.7 — `[Docs] Maintain a “Known Issues” list with workaround and owner`

- **Goal:** Reduce repeated debugging on the same problems.
- **AC:**
  - Known issues list includes: symptom, impact, workaround, and owner.
  - Links to Jira issues if they exist.
- **Tasks:**
  - Create `docs/KNOWN_ISSUES.md`.

---

### Story 7.8 — `[Docs] Ensure AGENTS.md and repo guidance is accurate`

- **Goal:** Local instructions stay current and prevent accidental anti-patterns.
- **AC:**
  - `AGENTS.md` exists at repo root (or is updated) and reflects current conventions.
  - Includes “how to add a new module/screen/provider” in the project style.
- **Tasks:**
  - Update/create `AGENTS.md` content as needed.

