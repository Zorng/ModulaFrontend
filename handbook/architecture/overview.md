# Architecture Overview

This document describes how the frontend is organized and how data/state flows through the app.

## Goals
- Make code placement obvious (teammates + agents).
- Avoid duplicated sources of truth.
- Keep UI responsive (no “freeze” during network calls).
- Keep modules composable (features don’t depend on other features’ UI).

## Repo layout

```
lib/
├─ app.dart                       # composition root (routes + top-level providers)
├─ main.dart                      # bootstrap (dotenv, runApp)
├─ core/                          # cross-cutting infrastructure + shared UI primitives
│  ├─ config/                     # environment flags (dotenv)
│  ├─ feedback/                   # user-safe error + messaging helpers
│  ├─ network/                    # Dio client + interceptors
│  ├─ routing/                    # route constants/enums
│  ├─ theme/                      # theming + responsive helpers
│  └─ widgets/                    # shared widgets used across features
└─ features/                      # feature modules (bounded contexts)
   ├─ auth/
   ├─ cash_session/
   ├─ inventory/
   ├─ menu/
   ├─ policy/
   ├─ reporting/
   ├─ sale/
   ├─ staff/
   └─ staff_attendance/
```

## Feature folder conventions (target)

New code should follow this convention. Legacy structures may exist and should be migrated over time.

```
lib/features/<feature>/
├─ domain/                  # business-centric models/rules (no HTTP/JSON)
│  └─ models/
├─ data/                    # backend integration (HTTP + DTO + mapping)
│  ├─ api/                  # Dio calls, DTO parsing, HTTP errors (target)
│  ├─ dto/                  # request/response DTOs mirroring backend payloads (target)
│  └─ repository/           # maps DTO → domain; returns domain models only (target)
└─ ui/
   ├─ view/                 # pages/screens
   ├─ widgets/              # feature-local reusable widgets
   └─ viewmodels/           # state owners (stores) + screen controllers
```

## State ownership model
- We do **not** enforce “1 viewmodel = 1 screen”.
- Use:
  - **Store (state owner)** for shared feature/domain state (cache + mutations).
  - **Screen controller (optional)** for screen-only state (filters/tabs/pagination/UI toggles).

Details: `handbook/architecture/providers.md`

## Data flow (one-directional)

```
UI (view) ──events──> Controller/Store ──calls──> Repository ──calls──> API
   ^                     |                               |
   |                     └────────── domain models ◀─────┘
   └────────────── renders state (loading/error/data)
```

Non-negotiable implications:
- UI must never depend on backend payload shapes directly (no DTO imports in UI/viewmodels).
- Backend-dependent flows must expose loading/error/data (no “freeze”).

## Hydration (login/tenant/branch → cross-feature refresh)

This app has **branch-scoped** and **tenant-scoped** state (policy, cash session, reports, etc).
When auth context changes (login/logout, tenant selection, branch switch), we must refresh those
cross-cutting stores consistently.

We centralize that logic in a single place:
- `lib/core/hydration/app_hydration_listener.dart`

### Why we do this (and what we avoid)
- Avoid side-effects inside provider `build()` methods (historically caused circular dependencies and
  “mutating providers during build” assertions).
- Avoid duplicating “on login, refresh X” logic in multiple screens.
- Make auth-context changes deterministic: **one event source** triggers **one hydration pathway**.

### What the hydration listener does

`AppHydrationListener` is a small `ConsumerStatefulWidget` mounted near the app root
(`lib/app.dart`). It listens to:
- `loginControllerProvider.session` (login/logout + tenant selection resulting session changes)
- `authTenantIdProvider` (active tenant changes)
- `authActiveBranchIdProvider` (active branch changes, including overrides)

When the session becomes:
- **null** (logout):
  - clears auth token + tenant + branch override providers
  - resets branch-scoped stores (currently policy + cash session)
- **non-null** (login/tenant selected):
  - sets `authAccessTokenProvider` from session
  - sets `authTenantIdProvider` from session (active tenant id)
  - triggers a refresh of branch-scoped stores when token+tenant+branch are all present

Hydration refresh is guarded by a simple “last hydrated” key:
`(token, tenantId, branchId)`.
If none of these changed, we skip refresh to prevent loops/redundant calls.

### Sequence (high level)

```
LoginController.session changes
  └─ AppHydrationListener applies session
      ├─ update auth token provider
      ├─ update active tenant provider
      └─ refresh branch-scoped stores (policy, cash session)

Active branch changes (e.g. portal dropdown)
  └─ AppHydrationListener refreshes branch-scoped stores again
```

### Implementation constraints (non-negotiable)
- The listener must not depend on feature UI.
- Hydration triggers must not run synchronously during widget tree construction:
  - `AppHydrationListener` defers initial sync until after first frame.
- Stores that participate in hydration must provide:
  - `reset()` (clear state on logout)
  - `load(...)` / `refresh(...)` (explicit reload on context change)

### How to add a new hydrated store
1) Ensure the store follows provider conventions (`Notifier`/`AsyncNotifier`) and exposes `reset()` + `load(...)`.
2) Add it to `AppHydrationListener._applySession` (reset path) and `_refreshBranchScopedStateIfNeeded` (load path).
3) Add a test or extend the existing one:
   - `test/core/hydration/app_hydration_listener_test.dart`

## Cross-feature dependencies

Allowed:
- Feature A imports Feature B **domain** models or **repository** interfaces when there is a clear shared contract.

Avoid:
- Importing another feature’s `ui/` from outside that feature.

If you need cross-feature UI reuse:
- Promote widgets to `lib/core/widgets/` once used by 2+ features (see `handbook/architecture/widgets.md`).

## Responsive behavior
All new screens/features must support breakpoints in `docs/responsive_breakpoints.md`.

## Non-negotiables
Authoritative list: `handbook/non_negotiables.md`
