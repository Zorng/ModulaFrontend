# Non‑Negotiables (Team + Agents)

These rules exist to keep the frontend predictable, maintainable, and regression-resistant.

## How to use this document
- Treat this file as the “contract” for PR reviews and agent work.
- If a rule must be broken for a valid reason, document it in the PR and create a follow-up Jira ticket to remove the exception.
- For deeper guidance and examples, see:
  - `handbook/architecture/overview.md`
  - `handbook/architecture/providers.md`
  - `handbook/architecture/navigation.md`
  - `handbook/architecture/widgets.md`
  - `handbook/quality/testing.md`
  - `handbook/quality/error_handling.md`

## PR checklist (quick)
- `flutter analyze` and `flutter test` pass (CI).
- No DTOs imported in UI/viewmodels.
- Backend-dependent UI shows loading/error/data (no “freeze”).
- Production UI does not show raw exceptions; uses `UserErrorMessage.build(...)` where needed.
- New pages use `go_router` for navigation.
- Screens touched behave correctly across breakpoints in `docs/responsive_breakpoints.md`.

## 1) State ownership model (no “1 screen = 1 viewmodel”)
- Use **State Owners (Stores)** as the single source-of-truth for feature/domain state; they can power multiple screens.
- Use optional **Screen Controllers** only for screen-local state (filters/tabs/pagination/UI toggles).

## 2) Backend source-of-truth must be async (no “freeze”)
- Anything that depends on backend truth must expose **loading/error/data** (prefer `AsyncValue<T>` via `AsyncNotifier`).
- Any backend call must surface progress in UI (disable actions, show loading, etc.).

## 3) Data layer boundaries are strict (DTO vs Domain)
- API layer (`data/api/…`) handles HTTP and parses **DTOs**.
- DTOs live in `data/dto/…` and mirror backend payload shapes.
- Repositories (`data/repository/…`) map **DTO → domain** and return **domain models only**.
- UI/viewmodels must not import DTOs.

## 4) Navigation is via `go_router` for pages
- New page navigation must use `context.go(...)` / `context.push(...)`.
- Do not use `Navigator.of(context).push(...)` for page navigation.
- Prefer passing **IDs** in routes over passing full objects via `extra` (exceptions only for short-lived flows).

## 5) Errors are user-safe in production
- Default production message: `Oops, something went wrong.`
- Technical details are hidden in production UI and enabled via `.env` in dev (e.g., `SHOW_DEBUG_ERRORS=true`).
- Provide a retry action when safe/possible.
- Prefer `UserErrorMessage.build(...)` (`lib/core/feedback/user_error_message.dart`) for consistent messaging.

## 6) Provider conventions (no legacy StateNotifierProvider)
- Do not introduce new `StateNotifierProvider`/`StateNotifier`.
- Use `AsyncNotifier` for backend truth; use sync `Notifier` for local/UI truth.
- Prefer explicit `load()/refresh()` methods (triggered from UI/controller) over implicit auto-fetch.

## 7) Widget reuse before duplication
- Check existing shared/feature widgets before creating a new one.
- Used in 2+ features → promote to `lib/core/widgets/`.
- Used in one feature → keep in `lib/features/<feature>/ui/widgets/`.
- If duplication is unavoidable, it must be minimal and tracked with a Jira “dedupe” ticket.

## 8) Screen composition rule (practical)
- Screens should not declare large custom widget classes.
- At most one small private widget is allowed if it stays trivial (≈ ≤30 LOC); otherwise extract to `ui/widgets/` or `core/widgets/`.

## 9) Regression prevention via CI
- PRs must pass `flutter analyze` and `flutter test` before merge.
- Bug fixes: add a regression test when feasible.
- New behavior/use cases: add at least one test (prefer unit; widget when UI logic is involved).
- UI-only styling/layout changes may omit tests but must include screenshots + manual test steps.
- If no test is added, include a reason and (when relevant) a follow-up Jira ticket.

## 10) Responsiveness is required
- New screens/features must support all breakpoints in `docs/responsive_breakpoints.md` (no overflow; correct navigation pattern per breakpoint).
- Material changes to existing screens must be verified across breakpoints; small changes should at least be checked on the primary target breakpoint.
