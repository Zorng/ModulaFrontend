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
