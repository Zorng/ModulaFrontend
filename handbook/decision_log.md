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
- Status: locked
- Canonical doc: `handbook/non_negotiables.md`
- Supporting docs:
  - `handbook/architecture/overview.md`
  - `handbook/architecture/providers.md`
  - `handbook/architecture/navigation.md`
  - `handbook/architecture/widgets.md`
  - `handbook/quality/testing.md`
  - `handbook/quality/error_handling.md`
- Summary:
  - State model: **Store + optional screen controller** (no “1 viewmodel = 1 screen”).
  - Strict layering: API/DTO ↔ repository ↔ domain (UI never imports DTOs).
  - Routing: `go_router` for pages.
  - Error UX: generic user-safe message in production; debug details via `.env`.
  - Quality gate: PRs must pass `flutter analyze` + `flutter test`.
  - Responsiveness: new screens must support breakpoints in `docs/responsive_breakpoints.md`.

### 4) Agent guide scope
- Status: locked
- Decision:
  - Create an agent-facing guide that defines required reads, preflight checks, and validation.
  - Source: `handbook/agents/agent_guide.md`
  - Repo root `AGENTS.md` points to the handbook guide.
- Output: what an agent must read/do before changes (commands, file entry points, validation).

### 5) `docs/` cleanup (optional, later)
- Status: completed
- Plan: `handbook/docs_cleanup.md`
- Output: reorganize `docs/` into clear buckets (product/spec vs archive) without breaking links.

## Notes
- Keep scope small: prefer a few strong rules over many weak ones.
- Make docs actionable: templates/checklists/examples > essays.
