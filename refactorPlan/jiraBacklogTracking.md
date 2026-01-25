# Jira Backlog Creation Tracker

Purpose: keep a durable record of decisions and progress while we translate the current frontend state into a clear Jira backlog (Epics → Stories → Tasks/Bugs/Spikes) that the team can execute without extra explanation.

---

## Status Legend

- **Drafting**: writing/rewriting scope, AC, tasks, QA steps
- **Reviewed**: agreed internally (ready to copy into Jira)
- **In Jira**: created in Jira with IDs linked here
- **Done**: delivered + verified

---

## Backlog Goals (What “good” looks like)

- Every Epic has a clear outcome, boundaries (in/out), and success criteria.
- Every Story has measurable AC + quick QA steps.
- Navigation + responsive foundations are defined before large UI work.
- Cross-cutting work (auth/tenant/branch, policy hydration, cash session gating, printing) is represented explicitly.
- Work is decomposed so multiple teammates can work in parallel with minimal merge conflict risk.

---

## Decisions Log (Keep this short and explicit)

| Date | Decision | Reason | Impacted Areas |
|---|---|---|---|
| 2026-01-17 | Jira hierarchy: Epics → Stories → Tasks/Bugs/Spikes | Enables tracking and delegation | Whole project |
| 2026-01-17 | Use visible navigation for “kebab destinations” | Improves discoverability; kebab should be secondary actions only | Navigation |
| 2026-01-17 | Roles not needed for backlog drafting (for now) | Team already has project knowledge base | Planning |
| 2026-01-17 | Wide screens use single global `NavigationRail` (no sub-rails) | Keep wide-screen chrome simple; section navigation stays in-page | Responsive + Navigation |
| 2026-01-22 | Standard navigation primitives: `NavigationRail` (wide) + `BottomNavigationBar` (module subpages on mobile, indexed stack) | Keeps destinations visible while preserving state; avoids hidden navigation and excessive kebab usage | Navigation + Responsive |

Add new decisions as we go.

---

## Open Questions (To resolve before/while drafting Epics)

- What is the minimum set of screens that must be “wide-screen ready” by March?
- Which printer integrations are “must-have” for demo vs production?
- What is the expected CI gate (analyze only vs analyze + unit + widget + integration)?
- Which modules are stable enough for refactor vs still changing rapidly?
- (Resolved) Kebab is secondary actions only; module sub-navigation uses bottom navigation on mobile (indexed stack).
  - Updated: module sub-navigation uses bottom navigation on mobile (indexed stack).

---

## Epic Progress Checklist

For each Epic: Draft → Review → Jira.

### Epic 1 — Responsive Widescreen (March)
- [x] Drafting
- [ ] Reviewed
- [ ] In Jira
- Links:
  - Spec/notes:
  - Epic notes: `refactorPlan/jira/epic1_responsive_widescreen.md`
  - Jira Epic:

### Epic 2 — Navigation UX Refactor (reduce kebab navigation)
- [x] Drafting
- [x] Reviewed
- [x] In Jira
- Links:
  - Spec/notes: `docs/navigation/nav_audit.md`
  - Epic notes: `refactorPlan/jira/epic2_navigation.md`
  - Jira Epic:

### Epic 3 — Testing & Quality Gate
- [x] Drafting
- [ ] Reviewed
- [ ] In Jira
- Links:
  - Epic notes: `refactorPlan/jira/epic3_testing_quality_gate.md`
  - Jira Epic:

### Epic 4 — Codebase Structure & Tech Debt Cleanup
- [x] Drafting
- [ ] Reviewed
- [ ] In Jira
- Links:
  - Epic notes: `refactorPlan/jira/epic4_codebase_structure_tech_debt.md`
  - Tech debt backlog: `handbook/tech_debt_backlog.md`
  - Jira Epic:

### Epic 5 — Printing (thermal + sticker)
- [ ] Drafting
- [ ] Reviewed
- [ ] In Jira
- Links:
  - Spec/notes:
  - Jira Epic:

### Epic 6 — UX Polish & Animations
- [ ] Drafting
- [ ] Reviewed
- [ ] In Jira
- Links:
  - Spec/notes:
  - Jira Epic:

### Epic 7 — Handover Readiness
- [x] Drafting
- [ ] Reviewed (Deferred)
- [ ] In Jira (Deferred)
- Status note: **Defer executing Epic 7 docs/runbook/ownership until Epic 3 + Epic 4 are completed** (testing + tech debt refactor will change procedures and ownership boundaries).
- Links:
  - Epic notes: `refactorPlan/jira/epic7_handover_readiness.md`
  - Jira Epic:

---

## Working Notes (Long-form)

Use this section for the “messy” discussion notes so the checklist stays clean.

### Notes — Epic 1

See `refactorPlan/jira/epic1_responsive_widescreen.md`.

### Notes — Epic 2

See `refactorPlan/jira/epic2_navigation.md`.


### Notes — Epic 3

See `refactorPlan/jira/epic3_testing_quality_gate.md`.

### Notes — Epic 4

See `refactorPlan/jira/epic4_codebase_structure_tech_debt.md`.

### Notes — Epic 5

- 

### Notes — Epic 6

- 

### Notes — Epic 7

See `refactorPlan/jira/epic7_handover_readiness.md`.

---

## Next Step

1) Confirm the Epic order (recommended: Navigation → Responsive → Testing → Structure → Printing → Polish → Handover).
2) Start drafting **Epic 2** with a concrete inventory-first pilot (kebab destinations → bottom nav → rail).
