# Auth Forgot Password UI

Goal: add a real forgot-password recovery flow to the frontend, aligned to the live `auth-v0` contract and the existing auth login/signup UI language.

## Why This Exists

The current frontend exposes only a misleading partial hint:

- desktop login shows `Forgot password?`
- mobile login does not
- there is no tap action
- there is no route
- there is no repository/API support

So the current UI implies support without actually providing recovery.

Backend contract is now active for:

- `POST /v0/auth/password-reset/request`
- `POST /v0/auth/password-reset/confirm`

This slice covers only the public forgot-password recovery flow.

It does **not** include:

- authenticated in-session change password
- account-page password management

## Locked Direction

### 1) Forgot password is a public auth flow

This flow belongs beside:

- login
- signup
- registration OTP verification

It does **not** belong inside account/settings.

### 2) Recovery is a two-step flow

Step 1:

- request reset OTP using phone number

Step 2:

- confirm OTP
- set new password

### 3) Do not reuse the current registration OTP page as-is

`OtpVerificationPage` is registration-specific and currently tied to `LoginController`.

Recovery should have its own routes and controller(s), even if some input/presentation patterns are later shared.

### 4) Success handling is forced sign-out / login return

Backend revokes all active sessions after successful reset confirm.

Frontend must:

- clear any locally stored auth session
- not assume current tokens remain valid
- send the user back to login after success

For the public recovery flow, the main visible outcome is:

- success message
- redirect to login

## Target UX

### Entry

Login page should expose `Forgot password?` as a real action on:

- desktop
- mobile

### Step A — Request reset

Fields:

- phone number

Actions:

- `Send OTP`
- `Back to login`

### Step B — Confirm reset

Fields:

- phone number
- OTP
- new password
- confirm new password

Actions:

- `Reset password`
- `Resend OTP`
- `Back to login`

### Success

- show success snackbar or inline success message
- redirect to login

## UI Rules

- Follow the existing auth visual language from:
  - `login_view.dart`
  - `signup_page.dart`
- Mobile:
  - constrained form page
- Desktop:
  - branded background + centered auth card
- Do not implement recovery as a modal
- Do not hide forgot-password on mobile

## Routing Direction

Preferred new routes:

- `/forgot-password`
- `/forgot-password/confirm`

Reason:

- clearer than overloading `/verify-otp`
- separates registration verification from password recovery

## Scope

Likely files:

- `lib/core/routing/app_router.dart`
- `lib/core/routing/routes/account_routes.dart` or auth route surface as appropriate
- `lib/features/auth/data/auth_api.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/data/remote_auth_repository.dart`
- `lib/features/auth/data/mock_auth_repository.dart`
- `lib/features/auth/ui/view/login_view.dart`
- `lib/features/auth/ui/view/login/widgets/login_form_content.dart`
- new forgot-password UI files under `lib/features/auth/ui/view/...`
- new controller/provider files under `lib/features/auth/ui/viewmodels/...`
- auth tests under `test/auth/...`

## Non-Goals

- no change-password page in this tracker
- no account-page password entry
- no redesign of signup or registration OTP flows beyond what is needed for consistency

---

## Phase 0 — Inventory and Contract Lock

- [x] confirm live backend contract for password reset request/confirm
- [x] inventory current frontend login/signup/otp surfaces
- [x] identify misleading existing forgot-password UI hints
- [x] lock route and UX direction

Output:

- implementation-ready assessment with scope boundary

### Phase 0 Findings

- current contract now supports:
  - `POST /v0/auth/password-reset/request`
  - `POST /v0/auth/password-reset/confirm`
- login currently shows `Forgot password?` only on desktop via `LoginFormContent`
- there is no actual action behind it
- current `OtpVerificationPage` is registration-specific and should not be overloaded
- existing auth visual patterns from `LoginPage` and `SignupPage` are good enough to reuse

---

## Phase 1 — Data and State Foundation

- [x] add API methods for:
  - password reset request
  - password reset confirm
- [x] add repository methods and result models
- [x] add mock support
- [x] add dedicated recovery controller/state

Output:

- frontend auth layer can request and confirm password reset

### Phase 1 Result

- added live password reset request/confirm methods in the auth API and repository
- added dedicated DTO/result mapping for password recovery
- added mock repository support for request/confirm flows
- added `ForgotPasswordController` as a dedicated recovery state owner

---

## Phase 2 — Routes and Pages

- [x] add dedicated routes:
  - forgot password
  - forgot password confirm
- [x] build mobile + desktop request page
- [x] build mobile + desktop confirm/reset page
- [x] keep auth styling consistent with login/signup

Output:

- two-page recovery flow is navigable and responsive

### Phase 2 Result

- added `/forgot-password` and `/forgot-password/confirm`
- added dedicated request and confirm pages instead of overloading registration OTP
- used a shared recovery shell to keep mobile and desktop auth presentation aligned with login/signup

---

## Phase 3 — Login Entry and UX Polish

- [x] wire `Forgot password?` as a real action on desktop login
- [x] expose the same entry on mobile login
- [x] remove the current fake desktop-only hint behavior
- [x] add success/error feedback and back-to-login handling

Output:

- recovery entry is consistent across breakpoints

### Phase 3 Result

- login now exposes a real forgot-password action on both desktop and mobile
- request flow can navigate forward with the resolved phone number
- confirm flow supports resend, validates password confirmation, and returns to login after success
- successful reset clears local auth state through the existing logout path, matching backend session revocation

---

## Phase 4 — Validation

- [x] `flutter analyze`
- [x] targeted `flutter test`
- [ ] manual QA checklist:
  - request OTP
  - invalid phone
  - invalid OTP
  - weak password
  - successful reset returns to login
  - mobile and desktop entry consistency

Output:

- forgot-password flow validated

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Contract and current UI assessed |
| 1 | Completed | API, repository, mock, and controller support added |
| 2 | Completed | Request/confirm routes and responsive pages added |
| 3 | Completed | Login entry wired on both breakpoints with success/error handling |
| 4 | In progress | `flutter analyze` and targeted tests passed; manual QA still open |
