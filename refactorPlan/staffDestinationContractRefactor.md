# Staff Destination Contract Refactor

Goal: rebuild the admin/staff-management destination around canonical v0 backend contracts under `integration/`, replacing legacy staff data-layer assumptions and stale UI flows.

## Source of Truth

- `integration/staff-management-v0.md`
- `integration/membership-v0.md`
- `integration/shift-v0.md`
- `integration/attendance-v0.md`

## Locked Decisions

- Backend API contracts under `integration/` are the source of truth.
- Local modspec for staff/attendance is obsolete for this refactor.
- Current staff-related data layer is legacy and should be replaced where it conflicts with canonical contracts.
- Adopt canonical endpoints directly; do not preserve compatibility with old frontend endpoint assumptions.
- Redesign staff domain models now.
- Request/placeholder surfaces without contract ownership should be removed or repurposed.

## Scope

The `Staff` destination on admin UI is responsible for:

- membership list/detail
- invite member
- revoke membership
- update role
- assign branches to membership
- assign/review shifts
- review attendance

Out of scope for this refactor:

- cashier attendance check-in/check-out screen
- account credentials / password management
- onboarding OTP / phone verification
- branch creation

---

## Phase 0 — Contract Mapping

- [x] Map contract endpoints to frontend surfaces
- [x] Define ownership by screen/subscreen
- [x] List payload/query params to support in UI
- [x] Mark endpoints that are admin-only vs manager-allowed

Output:
- contract-to-screen matrix

### Phase 0 Output — Contract To Screen Matrix

| Concern | Canonical Endpoint | Method | Allowed Roles | Token Scope | Proposed Screen Owner | Current Frontend Status |
|---|---|---|---|---|---|---|
| Staff list | `/v0/hr/staff` | `GET` | `OWNER`, `ADMIN`, branch-limited `MANAGER` | tenant | `Staff > List` root screen | Legacy endpoint/path assumptions |
| Staff detail | `/v0/hr/staff/:membershipId` | `GET` | `OWNER`, `ADMIN`, branch-limited `MANAGER` | tenant | `Staff > Detail` | Not implemented canonically |
| Membership branch assignments | `/v0/hr/staff/memberships/:membershipId/branches` | `GET` | `OWNER`, `ADMIN`, branch-limited `MANAGER` | tenant | `Staff > Detail > Branch assignments` | Not implemented canonically |
| Assign branches to membership | `/v0/hr/staff/memberships/:membershipId/branches` | `POST` | `OWNER`, `ADMIN`, branch-limited `MANAGER` | tenant | `Staff > Detail > Branch assignments` | Not implemented canonically |
| Invite membership | `/v0/org/memberships/invite` | `POST` | tenant permissioned admin/owner flow | tenant | `Staff > Invite` | Current invite flow uses old endpoint/payload |
| Change role | `/v0/org/memberships/:membershipId/role` | `POST` | permissioned admin/owner flow | tenant | `Staff > Detail > Role action` | Mock-only in real API mode |
| Revoke membership | `/v0/org/memberships/:membershipId/revoke` | `POST` | permissioned admin/owner flow | tenant | `Staff > Detail > Revoke action` | Mock-only in real API mode |
| Shift schedule read (membership) | `/v0/hr/shifts/memberships/:membershipId?from&to` | `GET` | `OWNER`, `ADMIN`, `MANAGER` | branch/tenant working context per contract | `Staff > Detail > Shifts` | Current UI fetches old `/users/:userId/shifts` contract |
| Shift schedule read (branch/team) | `/v0/hr/shifts/schedule?branchId&from&to&membershipId` | `GET` | `OWNER`, `ADMIN`, `MANAGER` | branch | `Staff > Shift planner` or future branch/team view | Not implemented |
| Shift pattern create/update/deactivate | `/v0/hr/shifts/patterns*` | `POST/PATCH` | `OWNER`, `ADMIN`, `MANAGER` | branch | `Staff > Detail > Shifts` or dedicated planner | Not implemented |
| Shift instance create/update/cancel | `/v0/hr/shifts/instances*` | `POST/PATCH` | `OWNER`, `ADMIN`, `MANAGER` | branch | `Staff > Detail > Shifts` or dedicated planner | Not implemented |
| Tenant attendance review | `/v0/attendance/tenant?branchId&accountId&occurredFrom&occurredTo&limit&offset` | `GET` | `OWNER`, `ADMIN` | tenant | `Staff > Attendance review` | Current page uses obsolete `/all` branch-style assumptions |
| Branch attendance review | `/v0/attendance/branch?accountId&occurredFrom&occurredTo&limit&offset` | `GET` | `MANAGER`, `ADMIN`, `OWNER` | branch | Manager attendance review, not primary admin tenant screen | Current admin page does not distinguish this properly |
| Invitation inbox | `/v0/org/memberships/invitations` | `GET` | authenticated account inbox flow | account/tenant membership context | Not part of admin staff-management destination | Current `Staff Request` tab has no canonical ownership |
| Accept invitation | `/v0/org/memberships/invitations/:membershipId/accept` | `POST` | invited account only | account | Not part of admin staff-management destination | Not relevant to admin staff screen |
| Reject invitation | `/v0/org/memberships/invitations/:membershipId/reject` | `POST` | invited account only | account | Not part of admin staff-management destination | Not relevant to admin staff screen |

### Phase 0 Output — Screen Ownership

Admin `Staff` destination should be decomposed into these contract-owned surfaces:

- `Staff list`
  - membership-centric list
  - search/filter/pagination
- `Staff detail`
  - membership summary
  - role action
  - revoke action
  - branch assignments
- `Invite`
  - invite membership first
  - then assign branches if needed
- `Shift assignment`
  - owned by shift contract, likely inside detail first
- `Attendance review`
  - owned by attendance contract, tenant-scoped for admin

Current frontend surfaces that do not map cleanly:

- `Staff Request` tab
  - current placeholder has no canonical admin-staff contract owner
  - invitation inbox belongs to invited account flow, not this admin destination
- current `Staff form`
  - mixes account/profile concerns with membership concerns
  - does not map to canonical contracts as a single create/edit form

### Phase 0 Output — Query / Payload Surface To Support

Staff list:

- `status`
- `search`
- `limit`
- `offset`

Attendance review:

- `branchId`
- `accountId`
- `occurredFrom`
- `occurredTo`
- `limit`
- `offset`

Branch assignment:

- body `branchIds: string[]`

Invite:

- body `tenantId`
- body `phone`
- body `roleKey`

Role update:

- body `roleKey`

Shift reads/writes:

- membership-scoped `from`, `to`
- branch/team schedule `branchId`, `from`, `to`, `membershipId`
- write payloads for patterns/instances plus `Idempotency-Key`

### Phase 0 Output — Immediate Structural Implications

- The current staff root tab structure is not contract-aligned.
- `Staff Request` should be removed or repurposed in this refactor.
- `StaffAttendancePage` should be rebuilt around tenant attendance review for admin.
- `StaffManagementPage` should stop acting like a full profile editor and become a membership detail/actions surface.
- Legacy DTOs and repositories should not be incrementally patched; they should be replaced by canonical concern-based modules.

---

## Phase 1 — Domain Remodel

- [x] Replace legacy single-branch `Staff` assumptions with membership-based models
- [x] Add explicit models for:
  - membership summary
  - membership detail
  - invitation result
  - role update result
  - revoke result
  - branch assignment result
  - shift schedule/query result
  - attendance review record
- [x] Define UI-facing mapping models only where needed

Output:
- canonical domain model set for staff destination

### Phase 1 Output — Canonical Domain Model Set

The legacy `Staff` model should be retired as the primary source of truth for this destination.

It currently mixes:

- membership lifecycle
- branch assignment
- personal profile fields
- auth/account concerns
- shift editing concerns

That shape does not match canonical contracts.

The replacement should be concern-based and contract-aligned.

#### 1) Membership Domain

Primary aggregate for the admin `Staff` destination.

`StaffMembershipSummary`

- `membershipId`
- `tenantId`
- `accountId`
- `phone`
- `roleKey`
- `membershipStatus`
- `firstName`
- `lastName`
- `staffProfileStatus`
- `invitedAt`
- `acceptedAt`
- `rejectedAt`
- `revokedAt`
- `pendingBranchIds`
- `activeBranchIds`

Use:

- staff list rows
- compact summary cards

`StaffMembershipDetail`

- all `StaffMembershipSummary` fields
- room for resolved branch metadata when fetched separately for display

Use:

- detail page header/content
- role/revoke/branch assignment entry point

`MembershipInviteResult`

- `membershipId`
- `tenantId`
- `accountId`
- `phone`
- `roleKey`
- `status`

Use:

- result of invite flow before/after branch assignment

`MembershipRoleUpdateResult`

- `membershipId`
- `tenantId`
- `roleKey`

Use:

- role update confirmation and local state replacement

`MembershipRevokeResult`

- `membershipId`
- `tenantId`
- `status`

Use:

- revoke action result and list/detail refresh

#### 2) Branch Assignment Domain

`StaffMembershipBranchAssignment`

- `membershipId`
- `tenantId`
- `membershipStatus`
- `pendingBranchIds`
- `activeBranchIds`

Use:

- read current assignment state
- write branch assignment result

Note:

- This is a separate concern from membership summary/detail because the contract treats it as a dedicated endpoint and result shape.

#### 3) Shift Domain

Adopt canonical `shift-v0` concepts directly.

`StaffShiftPattern`

- `id`
- `tenantId`
- `membershipId`
- `branchId`
- `daysOfWeek`
- `plannedStartTime`
- `plannedEndTime`
- `status`
- `effectiveFrom`
- `effectiveTo`
- `note`
- `createdAt`
- `updatedAt`

`StaffShiftInstance`

- `id`
- `tenantId`
- `membershipId`
- `branchId`
- `patternId`
- `date`
- `plannedStartTime`
- `plannedEndTime`
- `status`
- `note`
- `createdAt`
- `updatedAt`

`StaffMembershipShiftSchedule`

- `membershipId`
- `patterns`
- `instances`

Use:

- membership detail shift section
- future schedule planner UI

#### 4) Attendance Review Domain

`StaffAttendanceReviewRecord`

- `id`
- `tenantId`
- `branchId`
- `accountId`
- `type`
- `occurredAt`
- `createdAt`
- `locationVerification`
- `forceEndedByAccountId`
- `forceEndReason`
- `account`
- `branch`

`StaffAttendanceLocationVerification`

- `observedLatitude`
- `observedLongitude`
- `observedAccuracyMeters`
- `capturedAt`
- `status`
- `reason`
- `distanceMeters`

Use:

- admin attendance review list
- attendance detail rows/cards

#### 5) UI Projection Models

Only create UI-specific projection models where contract/domain shapes are too verbose for rendering.

Allowed examples:

- `StaffListRowVm`
- `StaffDetailHeaderVm`
- `StaffBranchAssignmentVm`
- `StaffAttendanceCardVm`

Rules:

- UI projections are derived from domain models
- UI projections must not become the write-source of truth
- DTOs do not cross into the widget layer

### Phase 1 Output — Layer Boundaries

Data DTOs:

- live under `lib/features/staff/data/dto/`
- match backend transport exactly
- camelCase contract parsing first, no UI assumptions

Domain models:

- live under `lib/features/staff/domain/models/`
- represent business entities for the feature
- stable across screens

UI projection models:

- live near the owning screen/viewmodel only if needed
- derived from domain

### Phase 1 Output — Structural Implications

- Current `Staff` model should not be extended further.
- Shift models should not be stuffed into a generic staff profile object.
- Attendance review models should not reuse the old simplified `staff_attendance_record` shape.
- Membership actions and branch assignment should not be represented as edits to one mutable “staff profile”.

### Proposed Module Grouping After Remodel

- `staff_membership_*`
  - list/detail/invite/role/revoke/branch assignment
- `staff_shift_*`
  - shift patterns, instances, schedule
- `staff_attendance_review_*`
  - tenant attendance review for admin

This grouping aligns the frontend with the backend contracts and avoids another overgrown “staff” model.

---

## Phase 2 — Data Layer Rewrite

- [x] Replace legacy `staff_management_api.dart` endpoint assumptions
- [x] Split data access by concern:
  - staff list/detail
  - membership actions
  - branch assignment
  - shift
  - attendance review
- [x] Remove real-API paths that are now mock-era leftovers
- [x] Keep mock repository only if still useful for isolated testing/dev

Output:
- contract-aligned repositories/apis

### Phase 2 Output — Data Layer Rewrite Plan

The current real-API implementation is too coupled to legacy assumptions and should be split by contract concern.

#### Replace These Legacy Ownership Patterns

Current problematic ownership:

- `staff_management_api.dart`
  - mixes staff list, legacy invite, and old shift fetch
- `staff_management_repository.dart`
  - mixes fetch/invite/update/delete in one repository
  - contains mock-era behavior branches for unsupported real APIs
- `staff_admin_attendance_api.dart`
  - assumes obsolete `/all` endpoint shape

These files should not remain the canonical real-API surface after refactor.

### Proposed Data Layer Modules

#### 1) Staff Membership Query Module

Owns:

- `GET /v0/hr/staff`
- `GET /v0/hr/staff/:membershipId`

Suggested files:

- `staff_membership_api.dart`
- `staff_membership_repository.dart`
- DTOs:
  - `staff_membership_summary_dto.dart`
  - `staff_membership_detail_dto.dart`

Responsibilities:

- parse canonical camelCase responses
- map query params: `status`, `search`, `limit`, `offset`
- map list/detail to membership domain models

#### 2) Membership Command Module

Owns:

- `POST /v0/org/memberships/invite`
- `POST /v0/org/memberships/:membershipId/role`
- `POST /v0/org/memberships/:membershipId/revoke`

Suggested files:

- `membership_command_api.dart`
- `membership_command_repository.dart`
- DTOs:
  - `membership_invite_result_dto.dart`
  - `membership_role_update_result_dto.dart`
  - `membership_revoke_result_dto.dart`

Responsibilities:

- command/write operations only
- idempotency support where contract expects it
- deterministic error mapping for invite/role/revoke actions

#### 3) Staff Branch Assignment Module

Owns:

- `GET /v0/hr/staff/memberships/:membershipId/branches`
- `POST /v0/hr/staff/memberships/:membershipId/branches`

Suggested files:

- `staff_branch_assignment_api.dart`
- `staff_branch_assignment_repository.dart`
- DTO:
  - `staff_membership_branch_assignment_dto.dart`

Responsibilities:

- branch assignment read/write
- keep branch assignment as a dedicated concern, not hidden in generic detail update flow

#### 4) Staff Shift Module

Owns:

- `GET /v0/hr/shifts/memberships/:membershipId`
- `GET /v0/hr/shifts/schedule`
- `POST/PATCH /v0/hr/shifts/patterns*`
- `POST/PATCH /v0/hr/shifts/instances*`

Suggested files:

- `staff_shift_api.dart`
- `staff_shift_repository.dart`
- DTOs:
  - `staff_shift_pattern_dto.dart`
  - `staff_shift_instance_dto.dart`
  - `staff_membership_shift_schedule_dto.dart`

Responsibilities:

- canonical shift reads/writes
- idempotency key attachment for writes
- separation between membership detail schedule and branch/team schedule

#### 5) Staff Attendance Review Module

Owns:

- `GET /v0/attendance/tenant`
- optionally later `GET /v0/attendance/branch`

Suggested files:

- `staff_attendance_review_api.dart`
- `staff_attendance_review_repository.dart`
- DTO:
  - `staff_attendance_review_record_dto.dart`

Responsibilities:

- tenant-scoped admin attendance review
- canonical filter params
- map location verification and force-end metadata correctly

### Mock Strategy

Mocks may remain for isolated testing/dev, but with stricter rules:

- mock modules must mirror the same repository interfaces as the canonical modules
- mock implementations must not distort the real domain model shape
- mock-only CRUD paths must not leak into real-repository code branches

This means:

- remove “real API fallback to unimplemented, simulate success” behavior
- prefer explicit repository interface + mock implementation pair

### Legacy Files To Retire Or Reduce

- `lib/features/staff/data/staff_management_api.dart`
  - replace with concern-specific APIs
- `lib/features/staff/data/staff_management_repository.dart`
  - replace with concern-specific repositories
- `lib/features/staff/data/staff_admin_attendance_api.dart`
  - replace with canonical attendance review API
- `lib/features/staff/data/staff_admin_attendance_repository.dart`
  - replace with canonical attendance review repository

Potentially retain temporarily only as migration wrappers if needed, but not as final ownership points.

### Interface Direction

Recommended repository interfaces:

- `StaffMembershipRepository`
- `MembershipCommandRepository`
- `StaffBranchAssignmentRepository`
- `StaffShiftRepository`
- `StaffAttendanceReviewRepository`

These should be injected separately into the screens/viewmodels that own them.

### Structural Consequences For Viewmodels

- `StaffListAsyncNotifier` should depend only on membership query repo
- detail/actions controller should depend on:
  - membership query repo
  - membership command repo
  - branch assignment repo
- shift controller should depend only on shift repo
- attendance review controller should depend only on attendance review repo

This removes the current monolithic “staff management repository” bottleneck.

### Phase 2 Output — Immediate Refactor Rule

Do not add any new canonical endpoint integration into the legacy all-in-one repository.

All new real API work for this feature should go into the concern-specific data modules above.

---

## Phase 3 — Staff List Rewrite

- [x] Lock `Staff` destination as a shell with horizontal tabs:
  - `Staffs`
  - `Attendance`
  - `Shift`
- [x] Keep shell state limited to selected tab + shared layout concerns
- [x] Rebuild list screen around canonical list endpoint
- [x] Support contract-backed filters/search
- [x] Show membership-centric fields instead of legacy profile assumptions
- [x] Reassess branch/role/status display for multi-branch memberships

Output:
- `Staff` shell locked with `Staffs` as the first tab surface
- contract-aligned staff list screen

### Phase 3 Output — `Staffs` Tab Ownership

The first tab is the canonical admin staff-management entry surface.

It owns:

- membership list query
- membership search and status filter
- pagination / incremental loading state
- empty / loading / error rendering for the membership list
- entry points into:
  - membership detail
  - invite flow

It does not own:

- attendance review state
- shift state
- account/profile editing
- auth/account credentials

### Phase 3 Output — Shell vs Tab State

`Staff` shell should own only:

- selected tab index / route segment
- shared page title / layout chrome

`Staffs` tab state should own:

- `search`
- `status`
- `limit`
- `offset` or next-page cursor equivalent used by frontend pagination
- current result set
- `isInitialLoading`
- `isRefreshing`
- `isLoadingMore`
- error state

This means the current monolithic list store should be replaced by a dedicated
list controller aligned to the canonical query surface.

### Phase 3 Output — Canonical Query Surface For First Pass

The first implementation pass of `Staffs` should support only the filters backed
by `GET /v0/hr/staff`:

- `search`
- `status`
- `limit`
- `offset`

Important first-pass rule:

- do not keep fake frontend-only branch or role filters as if they were
  canonical server filters

If branch/role narrowing is later required in the UX:

- either add backend support first
- or clearly label it as client-side derived filtering in a later iteration

For this rebuild, branch and role belong in row display/detail context, not as
primary list filters.

### Phase 3 Output — Remove These Current Legacy UI Assumptions

The rebuilt `Staffs` tab should explicitly remove:

- mock/API mode toggle
- plan/staff-limit banner logic
- branch filter dropdown
- role filter dropdown
- legacy status values that do not exist in contract-backed staff list
- staff-profile form assumptions leaking into the list surface

Canonical list statuses are:

- `ALL`
- `ACTIVE`
- `INVITED`
- `REVOKED`

### Phase 3 Output — List Row / Table Content

Each staff row/card should be membership-centric and derived from the canonical
staff list payload.

Required display fields:

- display name:
  - `firstName + lastName` when available
  - otherwise fallback to phone
- role
- membership status
- phone
- branch assignment summary:
  - invited memberships use `pendingBranchIds`
  - active memberships use `activeBranchIds`
- lifecycle timestamp summary:
  - invited at / accepted at / revoked at depending on status

Not first-pass fields:

- password
- gender
- local-only active toggle
- fake last-login placeholder column unless backend later provides it

Wide layout can remain table-based. Mobile layout can remain card/list-based.
Both must render the same canonical row information.

### Phase 3 Output — Detail Entry Behavior

Selecting a row should open membership detail, not a generic mutable staff
profile page.

Entry triggers:

- wide: `View` action or row tap
- mobile: card tap

Detail route payload should be minimal:

- prefer `membershipId`
- avoid passing a stale full legacy `Staff` object as the canonical source

### Phase 3 Output — Empty / Error UX

`Staffs` tab should distinguish:

- initial load failure
- refresh failure with stale data still visible
- no staff yet in tenant
- no search/status results

Recommended first-pass empty messages:

- no staff in tenant: `No staff memberships yet. Invite a team member to get started.`
- no filtered results: `No staff matches this search or status filter.`

### Phase 3 Output — Structural Consequences

- current `StaffHomePage` should become the `Staffs` tab surface inside the
  `Staff` shell, not a standalone feature entry
- current `StaffListAsyncNotifier` should be replaced or heavily rewritten to
  use canonical list query state
- current `StaffDataTable` and `StaffListCard` can be retained only if they are
  rebuilt around the new UI projection model
- current `Staff Request` tab should not block the shell rewrite and remains a
  legacy cleanup concern in phase 8

---

## Phase 4 — Membership Detail + Actions

- [x] Rebuild staff detail as membership detail
- [x] Implement role update flow
- [x] Implement revoke flow
- [x] Implement branch assignment flow
- [x] Remove fields that belong to account/auth instead of staff management

Output:
- detail/actions screen aligned to `staff-management-v0` + `membership-v0`

### Phase 4 Output — Detail Screen Ownership

The current detail surface should stop being a generic create/view/edit staff
form.

The rebuilt surface is a membership detail screen that owns:

- canonical membership detail fetch
- membership summary rendering
- role change action
- revoke action
- branch assignment view/edit entry

It does not own:

- account credential management
- phone/password editing
- profile fields not present in canonical staff detail contract
- shift editing
- attendance review

### Phase 4 Output — Screen Structure

First-pass membership detail should be sectioned like this:

1. **Identity summary**
   - display name fallback
   - phone
   - account/membership identifiers only where operationally useful

2. **Membership summary**
   - role
   - membership status
   - staff profile status
   - invited/accepted/revoked timestamps as available

3. **Branch assignment**
   - active branch assignments
   - pending branch assignments
   - edit action to replace assignments

4. **Actions**
   - change role
   - revoke membership

This should read as a management screen, not a profile form.

### Phase 4 Output — Action Rules

Role change:

- triggered from the detail screen
- submits to `POST /v0/org/memberships/:membershipId/role`
- should be a focused action flow, not full-page edit mode

Revoke:

- triggered from the detail screen
- submits to `POST /v0/org/memberships/:membershipId/revoke`
- must require confirmation
- UI copy should clearly state that revocation affects tenant membership, not
  just one branch

Branch assignment:

- owned from membership detail, because the action target is membership-scoped
- backed by:
  - `GET /v0/hr/staff/memberships/:membershipId/branches`
  - `POST /v0/hr/staff/memberships/:membershipId/branches`
- editing should behave as set/replace, matching the canonical command

### Phase 4 Output — Status-Aware Behavior

The detail screen must render status-aware summaries and actions based on:

- `INVITED`
- `ACTIVE`
- `REVOKED`

Examples:

- `INVITED`
  - emphasize invited timestamp
  - show pending branch assignments
- `ACTIVE`
  - emphasize accepted timestamp
  - show active branch assignments
- `REVOKED`
  - emphasize revoked timestamp
  - render the screen primarily as historical/read-only unless backend permits
    further actions

Where contract behavior is not explicitly guaranteed, action availability should
be derived conservatively and refined during implementation.

### Phase 4 Output — Remove These Legacy UI Assumptions

The detail screen should explicitly remove:

- first name / last name editable form fields as the primary interaction model
- email field
- password / confirm password fields
- gender selector
- active toggle
- schedule option controls
- weekday/time editors
- generic edit mode that implies full profile mutation

Those fields belong to legacy implementation assumptions and are not part of
canonical staff-management ownership.

### Phase 4 Output — State Management Direction

The detail/actions controller should be separate from the list controller and
should own:

- `membershipId`
- detail async state
- action-in-progress state per command:
  - role change
  - revoke
  - branch assignment save
- refresh-after-action behavior

Important rule:

- actions should not mutate a stale passed-in legacy object and pretend the
  screen is updated
- after each successful command, refresh canonical detail and notify the list
  surface to refresh or reconcile

### Phase 4 Output — Routing / Entry Behavior

Membership detail entry should be from the `Staffs` tab only.

Route payload rule:

- navigate with `membershipId`
- fetch detail from canonical source on entry
- do not use the old `StaffManagementPage(initialStaff: ...)` pattern as final
  ownership

### Phase 4 Output — Structural Consequences

- current `StaffManagementPage` should be retired or heavily repurposed; it is
  not a good base for canonical detail/actions
- current `StaffManagementStore` should not survive as a form-mode controller
  for create/view/edit profile semantics
- branch assignment belongs in this phase, not hidden in invite or shift flows
- shift remains a separate tab concern, even if the current legacy page mixes it
  into staff detail

---

## Phase 5 — Invite Flow

- [x] Replace legacy invite form payload assumptions
- [x] Implement contract-backed invite flow
- [x] Follow with branch assignment where needed
- [x] Validate role/phone flow against canonical membership invite contract

Output:
- contract-backed invite flow

### Phase 5 Output — Invite Flow Ownership

Invite is no longer “create staff profile”.

Invite owns only:

- tenant membership invite command
- minimal invite payload collection
- post-invite branch assignment entry when needed

Invite does not own:

- first/last name profile editing
- email capture
- password creation
- gender
- shift configuration
- staff active toggle

### Phase 5 Output — Canonical Invite Payload

First-pass invite flow should submit exactly the canonical membership invite
shape:

- `tenantId`
- `phone`
- `roleKey`

This replaces the current legacy assumptions around:

- `firstName`
- `lastName`
- `branchId`
- `note`
- `expiresInHours`
- `password`

Those fields should not appear in the canonical invite form unless a future
contract explicitly reintroduces them.

### Phase 5 Output — Invite UX Structure

Recommended first-pass invite flow:

1. open invite from `Staffs` tab
2. collect:
   - phone
   - role
3. submit invite
4. on success:
   - show membership result state
   - optionally continue to branch assignment for that invited membership

This should read as:

- `Invite team member`

not:

- `Add new staff profile`

### Phase 5 Output — Post-Invite Branch Assignment

Branch assignment should be a follow-up step, not embedded in the invite
payload.

Reason:

- canonical invite creates the membership
- canonical branch assignment targets `membershipId`

Therefore the supported sequence is:

1. `POST /v0/org/memberships/invite`
2. receive `membershipId`
3. optionally call `POST /v0/hr/staff/memberships/:membershipId/branches`

This is especially important for invited memberships, where assignments are
stored as `pendingBranchIds`.

### Phase 5 Output — State Management Direction

Invite flow should have its own focused controller/state, separate from:

- list state
- membership detail state
- shift state
- attendance state

Invite state should own:

- phone input
- selected role
- submit-in-progress state
- submit error state
- successful invite result
- optional handoff state into branch assignment

Important rule:

- successful invite should notify the `Staffs` tab to refresh/reconcile the
  list, because invited memberships should become visible immediately

### Phase 5 Output — Validation / Error UX

Invite flow should treat backend as source of truth for validation and surface
clear user messaging for expected errors such as:

- membership already active
- invalid payload / invalid role
- no tenant permission

The UX should not attempt to simulate account/profile validation that is no
longer part of the contract.

### Phase 5 Output — Structural Consequences

- current `InviteStaffRequestDto` should be retired; it encodes obsolete payload
  assumptions
- current invite path in `StaffManagementRepository.createInvite` should not be
  used as the canonical flow
- invite should no longer be implemented via the legacy “add staff” page
- the invite entry point belongs in the `Staffs` tab and should hand off to
  membership detail or branch assignment after success

---

## Phase 6 — Shift Assignment

- [x] Build `Shift` as the third horizontal tab inside the `Staff` shell
- [x] Design UI against canonical `shift-v0`
- [x] Decide how much of pattern/instance complexity is exposed in first pass
- [x] Implement read/write shift flows with idempotency handling

Output:
- `Shift` tab aligned to `shift-v0`

### Phase 6 Output — `Shift` Tab Ownership

The `Shift` tab is a dedicated admin/manager scheduling surface.

It owns:

- branch/team schedule query
- membership-specific shift query when drilling into one staff member
- shift pattern create/update/deactivate
- ad-hoc shift instance create/update/cancel

It does not own:

- membership invite
- membership role/revoke actions
- attendance review
- account/profile editing

### Phase 6 Output — Canonical Shift Concepts

The UI must be built around canonical shift concepts, not the legacy weekly
schedule abstraction:

- `ShiftPattern`
- `ShiftInstance`
- schedule query result:
  - `patterns`
  - `instances`

This means first-pass shift UI should stop pretending the only model is:

- 7 fixed weekday rows
- same-hours vs different-hours toggle

Those are implementation shortcuts from the old frontend, not canonical contract
ownership.

### Phase 6 Output — First-Pass UX Scope

The first pass should expose a manageable subset of the canonical model while
remaining honest to the API:

1. **Schedule filter bar**
   - branch
   - date range (`from`, `to`)
   - optional membership/staff filter

2. **Schedule results**
   - grouped display of patterns and instances
   - clear distinction between recurring planned shifts and ad-hoc overrides

3. **Pattern actions**
   - create pattern
   - update pattern
   - deactivate pattern

4. **Instance actions**
   - create ad-hoc instance
   - update instance
   - cancel instance

This lets the first pass stay canonical without exposing every possible advanced
calendar interaction immediately.

### Phase 6 Output — State Management Direction

`Shift` tab state should be separate from the `Staffs` and `Attendance` tabs.

It should own:

- selected branch filter
- date range
- optional membership filter
- schedule query async state
- per-command action state for:
  - create pattern
  - update pattern
  - deactivate pattern
  - create instance
  - update instance
  - cancel instance

Important rule:

- command state should be modeled independently from schedule query state so the
  whole tab does not freeze during one write action

### Phase 6 Output — Idempotency Rule

All shift writes require `Idempotency-Key`.

Therefore the shift command layer and viewmodels must:

- generate a stable idempotency key per user intent
- reuse it on retry for the same intent
- treat replayed successful or rejected responses as canonical outcomes

The `Shift` tab must not use legacy write helpers that ignore idempotency.

### Phase 6 Output — Remove These Legacy UI Assumptions

The rebuilt shift surface should explicitly remove:

- schedule editing embedded inside staff detail/profile page
- `same_hours` / `different_hours` toggle as the canonical abstraction
- 7-row weekly table as the only shift representation
- loading shifts via legacy `/users/:userId/shifts`

The existing weekly table widget may still be reused later as a derived display
component only if it renders canonical `ShiftPattern`/`ShiftInstance`
projections, not as the source model.

### Phase 6 Output — Routing / Entry Behavior

The default `Shift` tab is tenant/branch schedule management.

Optional drill-in behavior:

- selecting a staff member from this tab may narrow the schedule query to one
  membership
- but membership detail itself remains a `Staffs` tab concern

This keeps shift operations task-centered rather than embedding them back into
legacy staff profile flows.

### Phase 6 Output — Structural Consequences

- current schedule widgets under `staff_form/` should not remain the ownership
  point for canonical shift management
- current `fetchShiftSchedule(userId, branchId)` path is obsolete for the new
  tab design
- shift should be rebuilt from canonical `staff_shift_*` data modules planned in
  phase 2
- `StaffScheduleTable` can survive only as a presentation helper after the shift
  projection model is defined

---

## Phase 7 — Attendance Review

- [x] Build `Attendance` as the second horizontal tab inside the `Staff` shell
- [x] Rebuild admin attendance review on `/v0/attendance/tenant`
- [x] Support branch/date/account filters from contract
- [x] Stop relying on old `/all` endpoint assumptions

Output:
- `Attendance` tab aligned to `/v0/attendance/tenant`

### Phase 7 Output — `Attendance` Tab Ownership

The `Attendance` tab is the admin/owner review surface inside the `Staff`
destination.

It owns:

- tenant attendance query
- review filters
- paginated record display
- empty / loading / error states for attendance review

It does not own:

- cashier self check-in / check-out
- staff history under the cashier portal
- membership invite / role / revoke actions
- shift scheduling

### Phase 7 Output — Canonical Query Surface

The canonical admin/owner endpoint is:

- `GET /v0/attendance/tenant`

Supported first-pass filters:

- `branchId`
- `accountId`
- `occurredFrom`
- `occurredTo`
- `limit`
- `offset`

Important rule:

- do not continue using the old `/all` endpoint shape or the old query names
  (`employeeId`, `from`, `to`)

### Phase 7 Output — First-Pass UX Structure

Recommended first-pass `Attendance` tab layout:

1. filter row / filter section
   - branch selector
   - account/staff selector or search
   - date/time range

2. attendance result list
   - paginated cards or rows
   - newest-first ordering preserved from backend

3. record detail rendering
   - attendance type
   - occurred at
   - account summary
   - branch summary
   - location verification summary
   - force-end metadata when present

This keeps the first pass focused on review, not attendance operations.

### Phase 7 Output — State Management Direction

`Attendance` tab state should be independent from the other staff tabs.

It should own:

- selected branch filter
- selected account filter
- occurred-from filter
- occurred-to filter
- list pagination state
- initial loading state
- refresh state
- load-more state
- error state

Important rule:

- refreshing or paginating attendance results should not block the `Staffs` or
  `Shift` tabs

### Phase 7 Output — Record Content Rules

Attendance review rows/cards should be based on canonical `AttendanceScopedRecord`.

Required first-pass display content:

- account display name fallback
- phone
- branch name
- type (`CHECK_IN` / `CHECK_OUT`)
- occurred timestamp
- location verification summary:
  - status
  - reason when meaningful
  - distance if present
- force-end summary when present:
  - `forceEndedByAccountId`
  - `forceEndReason`

### Phase 7 Output — Scope / Role Boundaries

The `Staff` destination is admin-facing, so the tab should be designed around:

- admin/owner tenant review via `/v0/attendance/tenant`

Branch-scoped manager review via `/v0/attendance/branch` can be supported later
from a manager-specific surface, but should not distort the first-pass admin tab
design.

Likewise, `POST /v0/attendance/force-end` is part of the attendance module, but
it should be treated as a later action design decision unless product requires
it directly inside this tab.

### Phase 7 Output — Remove These Legacy Assumptions

The rebuilt attendance tab should explicitly remove:

- branch-only context assumption via active branch provider
- date-only filtering as the only review control
- obsolete `/all` endpoint usage
- legacy DTO/query naming tied to `employeeId`, `from`, `to`

### Phase 7 Output — Structural Consequences

- current `StaffAttendancePage` should be rebuilt as the `Attendance` tab, not
  as a standalone legacy page with its own outdated query ownership
- current `StaffAdminAttendanceApi` and repository should be replaced by the
  canonical attendance review data module from phase 2
- attendance view models should use canonical account/branch-scoped records, not
  the old simplified DTO assumptions

---

## Phase 8 — Legacy Cleanup

- [x] Remove or repurpose placeholder request tab
- [x] Remove dead fields/widgets tied to obsolete staff model
- [x] Update tests and docs

Output:
- no orphan legacy staff-management surfaces

### Phase 8 Output — Route / Surface Cleanup

The following legacy surfaces should be removed or repurposed during
implementation:

- `AppRoute.staffRequests`
  - remove unless a real contract-backed purpose is later defined
- `StaffRequestPage`
  - remove; it has no canonical owner in the rebuilt feature
- standalone `staffAdd` / placeholder add flow
  - remove if invite is rebuilt as the canonical add-entry surface from the
    `Staffs` tab
- legacy standalone staff detail/form ownership under current route semantics
  - replace with shell-backed `Staffs` tab -> membership detail flow

### Phase 8 Output — Legacy Controllers / Repositories To Retire

The following legacy ownership points should not survive as canonical feature
owners after implementation:

- `StaffListAsyncNotifier`
  - replace with canonical `Staffs` tab list controller
- `StaffManagementController`
  - replace with membership detail/actions controller + invite controller
- `StaffManagementRepository`
  - replace with concern-specific repositories from phase 2
- `StaffAdminAttendanceApi` / `StaffAdminAttendanceRepository`
  - replace with canonical attendance review data module

Migration wrappers are acceptable temporarily, but only as short-lived
compatibility layers.

### Phase 8 Output — Widgets / Form Fragments To Remove Or Repurpose

The following UI fragments are tied to the obsolete staff-profile form model and
should be removed or heavily repurposed:

- `staff_form/widgets/staff_authentication_section.dart`
- `staff_form/widgets/staff_basic_info_section.dart`
- `staff_form/widgets/staff_mobile_form_section.dart`
- `staff_form/widgets/staff_schedule_section.dart`
- any create/edit/view mode UI inside `StaffManagementPage`

Potential reuse is allowed only when the widget becomes:

- a pure presentation widget for canonical membership detail data, or
- a focused input widget for a canonical command flow

### Phase 8 Output — Domain / DTO Cleanup

The following legacy types should be retired from canonical ownership:

- legacy `Staff` domain model as the primary feature model
- `InviteStaffRequestDto`
- old `StaffDto` assumptions tied to deprecated endpoint shapes
- old attendance DTO/query assumptions tied to `/all`
- old shift schedule DTOs tied to `/users/:userId/shifts`

They may remain temporarily only behind migration adapters while the new domain
set from phase 1 is rolled in.

### Phase 8 Output — Test Cleanup

Tests should be updated to the new shell/tab architecture and canonical
contracts.

This includes:

- removing tests that treat `Staff Request` as a real feature
- removing tests that expect create/edit staff profile forms
- replacing tests that assert branch/role mock-era filters on the staff list
- adding contract-aligned tests for:
  - `Staffs` tab list/filter state
  - membership detail/actions
  - invite flow
  - `Shift` tab
  - `Attendance` tab

### Phase 8 Output — Documentation Cleanup

After implementation, documentation should be updated to reflect:

- the `Staff` destination as a 3-tab shell
- invite as membership onboarding
- membership detail replacing generic staff profile edit
- canonical shift and attendance ownership
- removal of the placeholder `Request` surface

### Phase 8 Output — Immediate Cleanup Rule

Do not preserve dead legacy surfaces “just in case” once their canonical
replacement is live.

For this feature, cleanup is part of completion, not a nice-to-have follow-up.

---

## Current Frontend Risks

- Current `Staff` domain model assumes one branch and mixes account/profile concerns.
- Current list/detail flows are built on old endpoint shapes.
- Update/revoke flows are mock-only in real API mode.
- Attendance review uses outdated endpoint/query assumptions.
- Shift handling is only partially integrated and not aligned to canonical shift module.

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Contract/screen ownership locked; request tab has no canonical owner |
| 1 | Completed | Canonical domain model set locked; legacy `Staff` model should be retired |
| 2 | Completed | Data layer split by contract concern locked; do not extend legacy all-in-one repository |
| 3 | Completed | `Staffs` tab UX/state locked; shell/list/detail-entry behavior aligned to canonical list contract |
| 4 | Completed | Membership detail/actions locked; legacy profile form assumptions removed from canonical surface |
| 5 | Completed | Invite flow locked as membership invite + optional branch assignment follow-up |
| 6 | Completed | `Shift` tab locked around canonical pattern/instance schedule management with idempotent writes |
| 7 | Completed | `Attendance` tab locked around canonical tenant attendance review with contract-backed filters |
| 8 | Completed | Legacy routes, form fragments, repositories, DTOs, tests, and docs cleanup scope locked |
