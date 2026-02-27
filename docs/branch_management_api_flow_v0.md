# Branch Management API Flow (`/v0`) - Regression Reference

Last reviewed: `2026-02-27`

## Source Of Truth

- `integration/api_contract/branch-v0.md` (updated `2026-02-27`)
- `integration/api_contract/auth-v0.md` (updated `2026-02-27`)

Frontend usage traces in:
- `lib/features/branchV2/data/branch_api.dart`
- `lib/features/auth/data/auth_api.dart`
- `lib/features/auth/data/remote_auth_repository.dart`
- `lib/features/branchV2/ui/viewmodels/branch_controller.dart`
- `lib/core/routing/workspace_route_guard.dart`

## Global Contract Rules

- Envelope success: `{ "success": true, "data": ... }`
- Envelope failure: `{ "success": false, "error": "...", "code": "..." }`
- Auth: `Authorization: Bearer <accessToken>`
- Context model: `tenantId` and `branchId` come from token context; do not send context override in query/body/header for branch/org/auth endpoints.

## Scope Boundary

- This document is for Branch Management only.
- Target frontend module: `lib/features/branchV2`.
- Menu module endpoints are intentionally excluded from this branch management reference.

## Current Work Scope

- Flow 1 (login/context bootstrap): `working`
- Flow 2 (branch selection screen load): `working`
- Flow 3 (select branch and enter workspace): `working`
- Flow 4 (create branch activation flow): `active workstream now`
- Flow 5 (branch profile settings APIs): `deferred/pending for later`

## Flow 1: Login And Context Bootstrap

### 1.1 Login

- Endpoint: `POST /v0/auth/login`
- Request body:

```json
{
  "phone": "+10000000001",
  "password": "Test123!"
}
```

- Success response (`200`) returns new tokens and context:

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt",
    "refreshToken": "opaque",
    "context": {
      "tenantId": null,
      "branchId": null
    }
  }
}
```

### 1.2 Tenant Context Selection

- List endpoint: `GET /v0/auth/context/tenants`
- Select endpoint: `POST /v0/auth/context/tenant/select`
- Select request body:

```json
{
  "tenantId": "uuid"
}
```

- Select success response (`200`):

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt",
    "refreshToken": "opaque",
    "context": {
      "tenantId": "uuid",
      "branchId": null
    }
  }
}
```

## Flow 2: Branch Selection Screen Load

This is the default branch-management entry flow after tenant selection.

### 2.1 Branch Context Options (Auth State)

- Endpoint: `GET /v0/auth/context/branches`
- Response shape:

```json
{
  "success": true,
  "data": {
    "state": "BRANCH_SELECTION_REQUIRED",
    "tenantId": "uuid",
    "selectedBranchId": null,
    "branches": [
      {
        "branchId": "uuid",
        "branchName": "Olympic"
      }
    ]
  }
}
```

### 2.2 Accessible Branches (Page List)

- Endpoint: `GET /v0/org/branches/accessible`
- Used to render branch tiles.
- Request body: none
- Success response (`200`) data list fields:
  - `branchId`, `tenantId`, `branchName`, `branchAddress`, `contactNumber`
  - `khqrReceiverAccountId`, `khqrReceiverName`
  - `attendanceLocationVerificationMode`, `workplaceLocation`, `status`

## Flow 3: Select Branch And Enter Workspace

### 3.1 Select Branch Context

- Endpoint: `POST /v0/auth/context/branch/select`
- Request body:

```json
{
  "branchId": "uuid"
}
```

- Success response (`200`):

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt",
    "refreshToken": "opaque",
    "context": {
      "tenantId": "uuid",
      "branchId": "uuid"
    }
  }
}
```

### 3.2 Verify Current Branch Profile

- Endpoint: `GET /v0/org/branch/current`
- Request body: none
- Success response (`200`) includes branch profile:
  - `branchId`, `tenantId`, `branchName`, `branchAddress`, `contactNumber`
  - `khqrReceiverAccountId`, `khqrReceiverName`
  - `attendanceLocationVerificationMode`, `workplaceLocation`, `status`

### 3.3 Frontend Routing Guard Behavior

- If branch workspace route is opened without active branch id, redirect to:
  - `/select-branch?reason=branch_context_required`
- Source: `guardBranchWorkspaceAccess` in `lib/core/routing/workspace_route_guard.dart`.

## Flow 4: Create Branch (Activation Flow)

Current contract does not provide direct `POST /v0/org/branches` create.
Creation is payment-gated activation.

### 4.1 Initiate Activation Draft

- Endpoint: `POST /v0/org/branches/activation/initiate`
- Header: `Idempotency-Key` (optional in contract, recommended; frontend auto-generates)
- Request body:

```json
{
  "branchName": "Main Branch"
}
```

- Success response:
  - `201` when draft/invoice created (`created: true`)
  - `200` when pending draft reused (`created: false`)
- `data` includes:
  - `draftId`, `tenantId`, `branchName`, `activationType`, `draftStatus`
  - `invoice` (`invoiceId`, `invoiceType`, `status`, `currency`, `totalAmountUsd`, `issuedAt`, `paidAt`)
  - `created`

### 4.2 Confirm Activation

- Endpoint: `POST /v0/org/branches/activation/confirm`
- Header: `Idempotency-Key` (frontend auto-generates)
- Request body:

```json
{
  "draftId": "uuid",
  "paymentToken": "PAID"
}
```

- Success response:
  - `201` when activation created (`created: true`)
  - `200` when same draft already activated (`created: false`)
- `data` includes:
  - `draftId`, `branchId`, `tenantId`, `branchName`
  - `activationType`, `status`, `invoiceId`
  - `paymentConfirmationRef`, `created`

### 4.3 Post-Confirm Reload

- Endpoint: `GET /v0/org/branches/accessible`
- Purpose: refresh list, highlight new branch, continue with branch selection.

### Flow 4 Implementation Focus (Now)

- Keep branch creation strictly on activation endpoints:
  - `POST /v0/org/branches/activation/initiate`
  - `POST /v0/org/branches/activation/confirm`
- Preserve both success paths:
  - initiate: `201 created: true` and `200 created: false`
  - confirm: `201 created: true` and `200 created: false`
- Preserve/create deterministic UI handling for contract reason codes:
  - initiate: `SUBSCRIPTION_UPGRADE_REQUIRED`, `FAIRUSE_HARD_LIMIT_EXCEEDED`, `FAIRUSE_RATE_LIMITED`, `IDEMPOTENCY_*`
  - confirm: `BRANCH_ACTIVATION_PAYMENT_REQUIRED`, `DRAFT_NOT_PENDING_PAYMENT`, `INVOICE_NOT_PAYABLE`, `DRAFT_NOT_FOUND`, `IDEMPOTENCY_*`
- After confirm success, reload with `GET /v0/org/branches/accessible`.

## Flow 5: Branch Profile Management Endpoints (Deferred)

This flow is intentionally deferred and not part of the current implementation scope.

These are part of branch contract and should be used for branch settings screens.

### 5.1 Update KHQR Receiver

- Endpoint: `PATCH /v0/org/branch/current/khqr-receiver`
- Request body:

```json
{
  "khqrReceiverAccountId": "bakong-account-id",
  "khqrReceiverName": "Main Branch Receiver"
}
```

- Success response (`200`): full `BranchProfile` payload in envelope.

### 5.2 Update Attendance Location Settings

- Endpoint: `PATCH /v0/org/branch/current/attendance-location`
- Request body:

```json
{
  "attendanceLocationVerificationMode": "checkin_only",
  "workplaceLocation": {
    "latitude": 11.5564,
    "longitude": 104.9282,
    "radiusMeters": 100
  }
}
```

- Success response (`200`): full `BranchProfile` payload in envelope.

## Error Codes To Preserve In UI

### Branch Activation Initiate

- `SUBSCRIPTION_UPGRADE_REQUIRED`
- `FAIRUSE_HARD_LIMIT_EXCEEDED`
- `FAIRUSE_RATE_LIMITED`
- `IDEMPOTENCY_CONFLICT`
- `IDEMPOTENCY_IN_PROGRESS`

### Branch Activation Confirm

- `BRANCH_ACTIVATION_PAYMENT_REQUIRED`
- `DRAFT_NOT_PENDING_PAYMENT`
- `INVOICE_NOT_PAYABLE`
- `DRAFT_NOT_FOUND`
- `IDEMPOTENCY_CONFLICT`
- `IDEMPOTENCY_IN_PROGRESS`

### Context/Access

- `TENANT_CONTEXT_REQUIRED`
- `BRANCH_CONTEXT_REQUIRED`
- `NO_MEMBERSHIP`
- `NO_BRANCH_ACCESS`

## Current Frontend Usage Matrix (Checked)

- `BranchSelectionPage` loads branches via `BranchController.loadInitial()`.
- `BranchController` uses `BranchRepository.loadAccessibleBranches()` -> `GET /v0/org/branches/accessible`.
- Branch tile tap calls `LoginController.selectBranch()` -> `POST /v0/auth/context/branch/select`.
- `RemoteAuthRepository.selectBranch()` verifies context with `GET /v0/org/branch/current`.
- Create branch dialog uses:
  - `POST /v0/org/branches/activation/initiate`
  - `POST /v0/org/branches/activation/confirm`
  - then reloads `GET /v0/org/branches/accessible`.

## BranchV2 Regression Hotspots To Fix Next

- Ensure no direct branch-create endpoint is introduced (`POST /v0/org/branches` is not in current contract).
- Keep create-branch flow strictly on activation endpoints:
  - `POST /v0/org/branches/activation/initiate`
  - `POST /v0/org/branches/activation/confirm`
- Keep branch entry strictly on auth context switch:
  - `POST /v0/auth/context/branch/select`
  - optional verify read: `GET /v0/org/branch/current`
- Keep branch tile rendering from `GET /v0/org/branches/accessible` only (assignment-scoped visibility from backend).
- Preserve guard redirect behavior for missing branch context:
  - `/select-branch?reason=branch_context_required`
