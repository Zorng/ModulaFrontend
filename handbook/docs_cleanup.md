# Docs Cleanup Plan (Product `docs/` vs Engineering `handbook/`)

Goal: make `docs/` easy to navigate and prevent it from becoming a “junk drawer”.

## Scope (what belongs where)

**Keep in `docs/` (product/spec artifacts):**
- Module specifications: `docs/modSpec/`
- API contracts: `docs/apiContracts/`
- API schemas: `docs/apiSchema/`
- UX breakpoints reference: `docs/responsive_breakpoints.md` (referenced by non‑negotiables)
- Product notes that support specs (e.g., device‑agnostic session notes)

**Move to `handbook/` (engineering/process):**
- Architecture guides (folders, providers, navigation, widgets)
- Testing strategy, CI rules, agent instructions
- “How to implement” notes (theme usage, common widget guidance, data‑layer testing notes)

## Non‑breaking rule (important)

We should assume existing links exist in:
- `refactorPlan/…`
- Jira tickets
- teammate notes

So for moved docs:
- leave a **stub** at the old path that links to the new path, or
- keep the old file but mark it as **Deprecated** and point to the canonical doc.

## Target structure (minimal change)

We keep the major folders as-is to avoid breaking links, and introduce clear “buckets” for anything else:

```
docs/
├─ README.md
├─ apiContracts/
├─ apiSchema/
├─ modSpec/
├─ navigation/                 # product navigation audits/notes (if still needed)
├─ responsive_breakpoints.md
├─ DEVICE_AGNOSTIC_SESSIONS.md
└─ _archive/                   # deprecated/legacy docs (kept for history)
   ├─ legacy_module_notes/
   └─ old_guides/
```

## Classification (what we should do with current top-level docs)

Candidate moves (engineering → `handbook/`):
- `docs/common_widgets_guide.md` → superseded by `handbook/architecture/widgets.md`
- `docs/testing_data_layer.md` → merge into `handbook/quality/testing.md` (or a new `handbook/quality/data_layer_testing.md`)
- `docs/theme_usage.md` → `handbook/architecture/theme.md` (or `handbook/architecture/ui_theme.md`)

Candidate archives (legacy/outdated → `docs/_archive/`):
- `docs/sale_module.md` (if superseded by `docs/modSpec/sale_module.md`)
- `docs/inventory_moudule_context.md` / `docs/inventory_context_extended.md` (keep if still referenced; otherwise archive)
- `docs/policy_module_context.md`, `docs/settings_module_context.md`, etc. (evaluate)

Keep (still product-spec related):
- `docs/DEVICE_AGNOSTIC_SESSIONS.md`
- `docs/responsive_breakpoints.md`

## Execution phases

### Phase 0 — Inventory + classify
- Create `docs/README.md` that explains what lives where.
- Make a quick table mapping each top-level `docs/*.md` file to:
  - `keep`, `move to handbook`, or `archive`

### Phase 1 — Create the `_archive/` bucket
- Add `docs/_archive/` with a short `README.md` describing why files are there.

### Phase 2 — Move engineering docs to `handbook/`
- Move/merge content into the right handbook doc.
- Leave stubs in `docs/` pointing to the canonical handbook doc.

### Phase 3 — Archive legacy product notes
- Move outdated module notes into `docs/_archive/legacy_module_notes/`.
- Leave stubs if needed.

### Phase 4 — Prevent regression
- Add a short rule to `handbook/non_negotiables.md` or `handbook/agents/agent_guide.md`:
  - “Do not add engineering docs under `docs/`; use `handbook/`.”

## Current status
- Phase 0: done (`docs/README.md`)
- Phase 1: done (`docs/_archive/`)
- Phase 2: done (moved key engineering docs; stubs left in `docs/`)
- Phase 3: done (archived legacy module notes; stubs left in `docs/`)
- Phase 4: pending (optional; can be added later if the team starts reintroducing process docs under `docs/`)

## Open questions (confirm before moving files)

1) Do we keep `docs/responsive_breakpoints.md` at its current path permanently (to avoid link churn)?
2) Do we want to fix `.gitignore` entries that currently ignore `docs/modSpec/` and `test/` for new files?

## Decisions (locked)
- Keep `docs/responsive_breakpoints.md` at its current path.
- Track `docs/modSpec/` and `test/` in git (removed ignore rules).
