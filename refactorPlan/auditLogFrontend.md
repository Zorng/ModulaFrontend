# Audit Log Frontend Plan

Goal: add a real tenant-scoped audit log frontend for the live `audit-v0` contract, covering both the data layer and a responsive owner/admin UI.

## Why This Exists

The backend contract now exposes:

- `GET /v0/audit/events`

But the frontend currently has:

- no audit feature module
- no audit route
- no audit navigation entry
- no DTO/model/repository support
- no list/filter/pagination UI

So the contract exists, but there is no usable frontend surface yet.

## Contract Lock

From [integration/audit-v0.md](/Users/mac/flutterProjects/modular/integration/audit-v0.md):

- base path: `/v0/audit`
- active read endpoint:
  - `GET /v0/audit/events`
- tenant context comes from token
- `tenantId` override is not supported
- access:
  - `OWNER`
  - `ADMIN`
- other roles are denied with `PERMISSION_DENIED`

Supported query parameters:

- `branchId`
- `actionKey`
- `outcome`
- `limit`
- `offset`

Returned row shape:

- `id`
- `tenantId`
- `branchId`
- `actorAccountId`
- `actorDisplayName`
- `actionKey`
- `outcome`
- `reasonCode`
- `entityType`
- `entityId`
- `metadata`
- `createdAt`

Important scope boundary:

- this tracker is read-only
- audit writes are internal backend behavior and not a frontend feature slice

## Locked Direction

### 1) Audit log is a tenant-layer feature

Audit reads are tenant-scoped and do not require branch context.

So the frontend surface should live in the tenant workspace, not the branch workspace.

### 2) Audit log is owner/admin only

Frontend should hide the entry point for:

- manager
- cashier
- unknown-role sessions

Backend remains authoritative if a forbidden user still reaches the route.

### 3) First cut is a list/detail-inspection UI, not an action surface

The first frontend implementation should cover:

- loading audit events
- filtering
- pagination
- inspecting event metadata

It should not add:

- write actions
- export
- deep-link routing by `entityType`
- live realtime audit streaming

### 4) Metadata should be inspectable without inventing a typed schema

`metadata` is generic JSON-like data.

So the UI should support a generic read-only metadata viewer rather than pretending it has a fixed typed shape.

### 5) Responsive presentation should differ by breakpoint

Recommended first cut:

- wide:
  - filter row + table/list layout
- small:
  - stacked filter controls + card/list layout

Metadata inspection can be:

- wide:
  - dialog or side sheet
- small:
  - bottom sheet or pushed detail page if needed

### 6) Branch filter should use known tenant branch choices

`branchId` is an optional filter.

The UI should source branch choices from the authenticated tenant/session context instead of asking the user to type raw IDs.

### 7) Action key filter can start simple

For the first cut, `actionKey` can be:

- a plain text filter field

This avoids blocking on a curated action-key catalog.

## Initial UX Direction

Page title:

- `Audit Log`

Core filter set:

- branch selector
- action key text field
- outcome selector:
  - `All`
  - `SUCCESS`
  - `REJECTED`
  - `FAILED`

Core event row information:

- timestamp
- action key
- outcome
- branch label when available
- actor account ID when available
- entity type / entity ID when available

Expanded inspection:

- reason code
- full metadata
- raw identifiers if useful

## Current State

Current audit-related frontend implementation is effectively absent.

What exists today:

- only the backend contract in [integration/audit-v0.md](/Users/mac/flutterProjects/modular/integration/audit-v0.md)
- one unrelated audit-copy mention in a cash-session modal

What does not exist:

- `lib/features/audit/`
- audit route in [app_router.dart](/Users/mac/flutterProjects/modular/lib/core/routing/app_router.dart)
- audit destination in [app_navigation_config.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_navigation_config.dart)
- audit API/repository/controller/page/tests

## Likely File Touchpoints

- `integration/audit-v0.md`
- `lib/core/routing/app_router.dart`
- `lib/core/widgets/navigation/app_navigation_config.dart`
- likely new audit route file under `lib/core/routing/routes/`
- new feature slice:
  - `lib/features/audit/data/`
  - `lib/features/audit/domain/`
  - `lib/features/audit/ui/`
- tests under:
  - `test/audit/`

## Non-Goals

- no audit write APIs
- no audit export/download
- no branch-workspace audit tab
- no cross-entity deep-link routing in phase 1
- no realtime audit subscription
- no special typed rendering for every possible `metadata` shape

---

## Phase 0 — Contract and Placement Lock

- [x] review live `audit-v0` contract
- [x] confirm there is no existing audit frontend slice
- [x] lock tenant-layer placement
- [x] lock owner/admin-only visibility

Output:

- implementation-ready scope and placement decision

### Phase 0 Findings

- audit is tenant-scoped, not branch-scoped
- current contract is read-only for frontend purposes
- current frontend has no audit route, nav entry, or feature module
- the clean first cut is an owner/admin tenant-workspace page with filters and pagination

---

## Phase 1 — Data Layer

- [x] add domain models for:
  - audit event
  - audit outcome
  - paginated audit event list
  - audit query/filter state
- [x] add DTO parsing for event rows and list envelope
- [x] add audit API client for:
  - `GET /v0/audit/events`
- [x] add repository layer
- [x] add focused API/repository tests

Output:

- typed frontend read lane for tenant audit events

### Phase 1 Result

- added a new `lib/features/audit/` slice with domain models, DTO parsing, API client, and repository mapping
- wired `AUDIT_API_PREFIX` into the shared config/env surface
- added focused API parsing coverage in `test/audit/audit_api_test.dart`
- backend later extended the active read payload with `actorDisplayName`, so frontend no longer needs a separate staff-directory lookup just to render actor names

---

## Phase 2 — State and Filtering

- [x] add controller/provider for:
  - initial load
  - refresh
  - pagination
  - branch filter
  - action key filter
  - outcome filter
- [x] reset query state correctly when tenant/session context changes
- [x] source branch filter options from authenticated tenant context
- [x] add controller tests

Output:

- stable audit list state with query/filter behavior

### Phase 2 Result

- added `AuditLogController` as the feature state owner
- implemented initial load, refresh, filter application, clear filters, and load-more pagination
- kept branch filtering tied to known tenant/session branches first, with branch-controller fallback
- added controller coverage in `test/audit/audit_log_controller_test.dart`

---

## Phase 3 — Routing and Navigation

- [x] add `AppRoute.audit`
- [x] add route wiring
- [x] add tenant-layer navigation entry for:
  - owner
  - admin
- [x] keep route hidden for non-authorized roles in frontend navigation
- [x] add route-access/navigation tests

Output:

- audit log is reachable from the tenant workspace for the correct roles

### Phase 3 Result

- added `/audit` route wiring through a dedicated `audit_routes.dart`
- added `Audit Log` to tenant-layer owner/admin navigation only
- extended app redirect/guard logic so owner/admin can reach the route while managers/cashiers are blocked
- added route and navigation visibility coverage in `test/audit/audit_route_access_test.dart`

---

## Phase 4 — Audit Log UI

- [x] build responsive audit log page
- [x] add filter controls
- [x] build wide list/table presentation
- [x] build small-screen list/card presentation
- [x] add empty/loading/error states
- [x] add metadata inspection UI
- [x] add page/widget tests

Output:

- usable audit log page across breakpoints

### Phase 4 Result

- added `AuditLogPage` with:
  - branch filter
  - outcome filter
  - action-key filter
  - list/count summary
  - refresh/load-more states
- wide view uses a spacious filter row and card list
- small view uses stacked controls and bottom-sheet detail inspection
- metadata inspection is generic and read-only through JSON rendering
- added widget coverage in `test/audit/audit_log_page_test.dart`

---

## Phase 5 — Access and UX Polish

- [x] handle forbidden/unauthorized responses cleanly
- [x] confirm branch filter label behavior when `branchId` is null
- [x] confirm actor/entity display fallbacks when IDs are null
- [x] add manual QA checklist

Manual QA checklist:

- [ ] owner can open audit log from tenant workspace
- [ ] admin can open audit log from tenant workspace
- [ ] manager/cashier do not see the audit entry
- [ ] branch filter narrows rows correctly
- [ ] outcome filter narrows rows correctly
- [ ] action-key filter narrows rows correctly
- [ ] metadata inspection renders without overflow on small and wide layouts
- [ ] pagination works without dropping active filters

Output:

- audit log UI is role-safe and ready for real-data validation

### Phase 5 Result

- unauthorized manager access is blocked by routing and covered by tests
- tenant-level/null branch events render as `Tenant level`
- missing actor IDs render as `System`
- missing entity/reason values render with safe fallbacks instead of blank/broken layout
- manual QA checklist is recorded, but the checks themselves are still pending

---

## Phase 6 — Optional Follow-up

- [ ] decide whether entity-specific deep links are worth adding later
- [ ] decide whether export/download is needed later
- [ ] decide whether action-key presets should replace raw text input later

Output:

- future direction recorded without bloating the first cut

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Contract and placement assessed |
| 1 | Complete | Data models, API, repository, API test landed |
| 2 | Complete | Controller, filtering, pagination, controller tests landed |
| 3 | Complete | Route and owner/admin tenant nav entry landed |
| 4 | Complete | Responsive audit page and widget tests landed |
| 5 | Complete | Access polish and fallback behavior locked; manual QA still pending |
| 6 | Not started |  |
