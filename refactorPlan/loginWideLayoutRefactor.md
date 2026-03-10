# Login Wide Layout Refactor

Goal: keep the current mobile login flow intact while introducing a real wide-screen login layout with a dedicated branding panel and a desktop-specific form composition.

## Scope
- `lib/features/auth/ui/view/login_view.dart`
- `lib/features/auth/ui/viewmodels/login_controller.dart` only if needed for presentation-safe wiring
- feature-local auth UI widgets if extraction is needed

## Locked Direction
- Mobile login remains the primary small-screen layout.
- Wide login becomes a real 2-panel layout:
  - left: brand panel
  - right: login form panel
- Login logic, routing, and state ownership stay unchanged.
- Form content should be shared between breakpoints where practical.
- Wide-only polish such as brand panel, desktop spacing, and secondary links are presentation concerns only.

## Phase 0 — Current-State Inventory
- [x] Confirm current login logic/state can remain untouched
- [x] Confirm current desktop login is only the mobile form inside a card
- [x] Lock touched scope to presentation/layout first

### Findings
- `LoginPage` in `lib/features/auth/ui/view/login_view.dart` already switches by breakpoint.
- `_DesktopLoginForm` currently just wraps `_MobileLoginForm` in a centered `Card`.
- `LoginController` already owns the auth flow correctly:
  - loading/error state
  - phone-verification redirect
  - tenant/branch routing after successful login
- The main gap is presentation, not auth behavior.

## Phase 1 — Shared Form Extraction
- [x] Extract a shared login form content widget
- [x] Keep controllers/listeners in `LoginPage`
- [x] Avoid duplicating login field/action logic across breakpoints

## Phase 2 — Wide Shell Layout
- [x] Build a true 2-panel desktop layout
- [x] Left panel: brand surface
- [x] Right panel: form surface
- [x] Ensure the layout only applies on large breakpoints

## Phase 3 — Desktop Form Polish
- [x] Match the desktop visual hierarchy more closely:
  - title
  - rounded fields
  - primary button
  - secondary links
- [x] Keep loading/error behavior intact
- [x] Decide how `Forget password?` should be shown if flow is not implemented

## Phase 4 — Responsive Validation
- [x] Verify mobile layout remains unchanged in behavior
- [x] Verify wide layout matches intended desktop composition
- [x] Add/adjust widget coverage where useful

## Notes
- This refactor is layout-only unless a small UI-only routing hook is needed for secondary links.
- No auth flow rewrite is intended.
