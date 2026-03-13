# Invitation Inbox Flow Refactor

Goal: add the account-layer invitation inbox so invited users can receive, accept, or reject tenant membership invitations from the tenant-selection app bar.

## Source of Truth

- `integration/membership-v0.md`

## Locked Decisions

- Invitation inbox belongs to the `account` layer.
- Entry point is the `Inbox` action on the tenant-selection app bar.
- Accept/reject must use canonical endpoints under `/v0/org/memberships/invitations/*`.
- After accept, the app must refresh memberships/session state but still keep explicit `select tenant -> select branch` flow.
- After reject, the app removes the invitation from inbox and does not change tenant context.
- Mobile should use a full page for the inbox.
- Wide can use the same page first; modal/sheet optimization is optional follow-up.
- Badge/count on the inbox action is desirable, but the inbox surface and actions are higher priority.

## Scope

In scope:

- invitation inbox list
- accept invitation
- reject invitation
- refresh tenant memberships after invitation mutation
- connect tenant-selection app-bar inbox button
- account-layer empty/loading/error states

Out of scope:

- tenant/branch auto-entry after accept
- invitation creation flow inside this plan
- invitation notifications outside the app
- account/settings redesign

---

## Phase 0 — Contract Mapping + Current State

- [x] Map inbox, accept, and reject contract payloads/responses
- [x] Confirm current frontend entry point and missing pieces
- [x] Define required post-action refresh behavior

Output:
- contract-to-screen notes

### Phase 0 Notes

Endpoints:

- `GET /v0/org/memberships/invitations`
- `POST /v0/org/memberships/invitations/:membershipId/accept`
- `POST /v0/org/memberships/invitations/:membershipId/reject`

Expected inbox item fields:

- `membershipId`
- `tenantId`
- `tenantName`
- `roleKey`
- `invitedAt`
- `invitedByMembershipId`

Expected accept result:

- `membershipId`
- `tenantId`
- `status = ACTIVE`
- `activeBranchIds`

Expected reject result:

- `membershipId`
- `tenantId`
- `status = REVOKED`

Current frontend status:

- tenant-selection app bar already has an `Inbox` icon button in [tenant_selection_page.dart](/Users/mac/flutterProjects/modular/lib/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart)
- no inbox route/page exists yet
- no invitation data layer exists yet
- no account-layer refresh flow exists yet for accepted invitations

---

## Phase 1 — Data Layer

- [x] Add invitation inbox DTO/domain model
- [x] Add invitation inbox API/repository
- [x] Add accept/reject command API/repository
- [x] Support idempotency for accept/reject writes

Output:
- canonical invitation data layer

### Phase 1 Output

Implemented under `auth` because the inbox is account-scoped:

- domain models:
  - `lib/features/auth/domain/models/membership_invitation.dart`
- DTOs:
  - `lib/features/auth/data/dto/membership_invitation_dto.dart`
- API:
  - `lib/features/auth/data/membership_invitation_api.dart`
- repository:
  - `lib/features/auth/data/membership_invitation_repository.dart`

Notes:

- accept/reject now use account-scoped idempotency metadata
- repository maps accept/reject contract statuses into typed domain status values
- no UI/state wiring yet; that starts in phase 2

---

## Phase 2 — State Management

- [x] Add inbox list controller
- [x] Add accept/reject action handling with loading states
- [x] Support list refresh after mutation
- [x] Define how tenant memberships/session are refreshed after accept

Output:
- account-layer invitation inbox state model

State expectations:

- loading
- loaded invitations
- empty
- inline mutation error
- per-item action loading where practical

### Phase 2 Output

Implemented:

- `lib/features/auth/ui/viewmodels/membership_invitation_inbox_controller.dart`
- `test/auth/membership_invitation_inbox_controller_test.dart`

Notes:

- inbox state is now owned by an `AsyncNotifier`
- controller keeps stale list data during refresh failure and exposes inline error
- accept/reject track per-invitation loading ids
- accept updates the persisted auth session through
  `LoginController.upsertSessionTenantMembership(...)`
- invite list is refreshed after mutation, with local row removal as fallback

---

## Phase 3 — Inbox UI

- [x] Add invitation inbox page
- [x] Show invitation cards/list rows with tenant, role, invited timestamp
- [x] Add empty, loading, and retry states
- [x] Wire tenant-selection app-bar inbox button to the page

Output:
- navigable inbox surface from account layer

UI expectations:

- mobile-first full page
- white cards/background aligned with current auth/tenant screens
- clear `Accept` and `Reject` actions

### Phase 3 Output

Implemented:

- `lib/features/auth/ui/view/invitation_inbox/invitation_inbox_page.dart`
- `test/auth/membership_invitation_inbox_page_test.dart`

Notes:

- inbox is now a non-shell account-layer route at `/invitations`
- tenant-selection app bar now pushes the inbox page
- inbox page renders loading, fatal error with retry, empty state, and invite cards
- invite cards show tenant, role, invited timestamp, and visible accept/reject actions

---

## Phase 4 — Accept / Reject Flow

- [x] Wire `Accept`
- [x] Wire `Reject`
- [x] Keep user on inbox page after action
- [x] Remove or refresh the affected invitation row
- [x] Show deterministic success/error feedback

Output:
- working invitation mutation flow

Behavior rules:

- accept:
  - refresh invitation list
  - refresh memberships/session snapshot
  - do not auto-enter tenant or branch
- reject:
  - refresh invitation list only

### Phase 4 Output

Implemented:

- `lib/features/auth/ui/viewmodels/membership_invitation_inbox_controller.dart`
- `lib/features/auth/ui/view/invitation_inbox/invitation_inbox_page.dart`
- `test/auth/membership_invitation_inbox_controller_test.dart`
- `test/auth/membership_invitation_inbox_page_test.dart`

Notes:

- controller mutations now return deterministic success/failure results
- inbox page shows an inline feedback card for accept/reject outcomes and keeps the user on the inbox
- successful mutations remove the affected row through refresh/fallback logic
- accepted invitations still do not auto-enter tenant or branch

---

## Phase 5 — Tenant Selection Refresh Integration

- [x] Refresh tenant selection state after accepted invitation
- [x] Ensure newly accepted tenant appears in tenant-selection list immediately
- [ ] Optionally add inbox badge/count on tenant-selection app bar

Output:
- accepted invitation visible immediately in tenant-selection flow

### Phase 5 Output

Implemented:

- `test/auth/membership_invitation_inbox_page_test.dart`

Notes:

- no additional production-side refresh hook was required
- tenant selection already reacts to accepted invitations through updated
  `LoginController` session memberships
- regression coverage now proves the accepted tenant appears in
  tenant-selection immediately after returning from the inbox
- inbox badge/count remains optional follow-up work

---

## Phase 6 — Validation

- [ ] Manual test invited account flow
- [ ] Manual test reject flow
- [x] Add focused tests for inbox list + accept/reject controllers
- [x] Add route/widget test for tenant-selection inbox entry

Output:
- validated invitation inbox flow

### Phase 6 Output

Automated validation completed:

- `test/auth/membership_invitation_inbox_controller_test.dart`
- `test/auth/membership_invitation_inbox_page_test.dart`
- `flutter analyze`
- `flutter test`

Still pending manual QA:

- invited account flow in a real app session
- reject flow in a real app session

Manual checks:

1. Invite an account from `Staff`.
2. Log in as invited account.
3. Open inbox from tenant-selection app bar.
4. Confirm invite card shows correct tenant and role.
5. Accept invite and verify tenant appears in tenant selection without relogin.
6. Reject invite and verify it disappears from inbox.
7. Confirm tenant/branch are still explicitly selected after acceptance.

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Contract and current-state mapping locked |
| 1 | Completed | Canonical auth-side invitation data layer implemented |
| 2 | Completed | Inbox controller + accept/reject/session refresh behavior implemented |
| 3 | Completed | Inbox page + route + tenant-selection entry implemented |
| 4 | Completed | Accept/reject flow wired with deterministic feedback |
| 5 | Completed | Tenant selection refresh path validated with router/widget regression test |
| 6 | In progress | Automated validation complete; manual QA pending |
