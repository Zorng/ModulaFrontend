# Architecture Overview

This document describes how the frontend is organized and how data/state flows through the app.

## Goals
- Make code placement obvious (teammates + agents).
- Avoid duplicated sources of truth.
- Keep UI responsive (no “freeze” during network calls).

## Folder conventions (per feature)

Each feature follows:

```
lib/features/<feature>/
├─ domain/                  # business-centric models/rules (no HTTP/JSON)
│  └─ models/
├─ data/                    # backend integration (HTTP + DTO + mapping)
│  ├─ api/                  # Dio calls, DTO parsing, HTTP errors
│  ├─ dto/                  # request/response DTOs mirroring backend payloads
│  └─ repository/           # maps DTO → domain; returns domain models only
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

## Responsive behavior
All new screens/features must support breakpoints in `docs/responsive_breakpoints.md`.

## Non-negotiables
Authoritative list: `handbook/non_negotiables.md`

