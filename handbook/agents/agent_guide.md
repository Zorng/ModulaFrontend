# Agent Guide (Codex/AI)

Scope: this guide defines what an AI agent must **read**, **respect**, and **verify** before/after making changes in this repo.

## Must-read (always)
- `handbook/non_negotiables.md`
- `docs/responsive_breakpoints.md`
- `handbook/architecture/overview.md`
- Testing conventions: `handbook/quality/testing.md`
- Handover index: `handbook/handover/README.md`

## Read if relevant
- Module specs: `docs/modSpec/…`
- API contracts: `docs/apiContracts/…`
- Feature notes/plans (if referenced by the task): `refactorPlan/…`
- Runbook + checklists: `handbook/handover/runbook.md`, `handbook/handover/pr_checklist.md`, `handbook/handover/release_checklist.md`
- Ownership map: `handbook/handover/ownership.md`

## Preflight checklist (before changing code)
1) Identify the feature/module(s) touched and locate the relevant modspec + API contract.
2) Search for existing implementations before adding new code:
   - existing widgets (`lib/core/widgets`, `lib/features/<feature>/ui/widgets`)
   - existing providers/viewmodels (`lib/features/<feature>/ui/viewmodels`)
3) Confirm routing approach:
   - pages use `go_router` (`context.go`/`context.push`), not `Navigator.push`
   - new routes must be added via `AppRoute` + `appRouterProvider`
4) Confirm state approach:
   - backend truth → `AsyncValue` (prefer `AsyncNotifier`) + explicit `load()/refresh()`
   - local/UI truth → sync `Notifier`
   - do not introduce new `StateNotifierProvider`
5) Confirm data-layer boundaries:
   - API parses DTOs
   - repository maps DTO → domain
   - UI/viewmodels do not import DTOs

## Implementation checklist (while coding)
- Keep changes minimal and localized to the requested scope.
- Prefer reuse-first for widgets; if duplication is unavoidable, leave a Jira-tracked follow-up to dedupe.
- Avoid widget bloat: extract large sections into `ui/widgets/` (feature) or `core/widgets/` (shared).
- Error UX:
  - production UI shows: `Oops, something went wrong.`
  - technical details are enabled/disabled via `.env` (e.g., `SHOW_DEBUG_ERRORS`)
  - prefer `UserErrorMessage.build(...)` (`lib/core/feedback/user_error_message.dart`) for consistent messaging

## Validation checklist (before handing back)
- Run `flutter analyze` and `flutter test` locally before handing back changes.
- Ensure UI does not “freeze” during backend calls (loading state visible; actions disabled).
- Confirm responsive behavior per `docs/responsive_breakpoints.md` for screens touched.

## Output format expectation (for PRs / handoff)
- Summarize what changed and where.
- Provide manual test steps (what to click, expected results).
- Call out any follow-up debt tickets created/needed (e.g., widget dedupe, missing tests).
