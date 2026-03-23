# Operational Notification Frontend Plan

Goal: implement in-app operational notifications on web/mobile using the existing `/v0/notifications` contract, starting with a stable data layer and then layering unread badge, inbox UI, and SSE.

## Scope
- `integration/operational-notification-v0.md`
- `lib/core/hydration/context_scoped_runtime_resource.dart`
- `lib/core/hydration/app_hydration_listener.dart`
- `lib/core/routing/app_router.dart`
- `lib/core/widgets/navigation/*`
- new feature slice under `lib/features/notification/`

## Current State
- Backend contract exists and is complete.
- Frontend has no notification models, API, repository, inbox UI, unread badge, or SSE client.
- The working-context runtime seam already exists and is suitable for a context-bound SSE connection.
- The invitation inbox feature provides a good page/controller pattern reference, but it is unrelated to operational notifications.

## Phase 0 — Assessment
- [x] Confirm contract surface and event types
- [x] Confirm there is no existing operational notification frontend implementation
- [x] Identify runtime seam for one-context SSE binding

## Phase 1 — Data Layer
- [x] Add domain models for notification item, inbox page, unread count, and read results
- [x] Add DTO parsing for inbox/list/detail/read envelopes
- [x] Add notification API client for:
  - `GET /v0/notifications/inbox`
  - `GET /v0/notifications/unread-count`
  - `GET /v0/notifications/:notificationId`
  - `POST /v0/notifications/:notificationId/read`
  - `POST /v0/notifications/read-all`
- [x] Add repository/provider layer
- [x] Add focused API/repository tests

## Phase 2 — Inbox State
- [x] Add unread-count/inbox controller(s)
- [x] Support initial load, refresh, pagination, mark-read, mark-all-read
- [x] Add controller tests

## Phase 3 — UI
- [x] Add operational notification inbox page
- [x] Add unread badge surface in navigation/app bar
- [x] Add route wiring
- [x] Add page/widget tests

## Phase 4 — SSE Runtime
- [x] Add SSE client with authenticated header support
- [x] Bind exactly one stream to active working context
- [x] Reconnect with backoff and inbox refresh on reconnect
- [x] Update unread badge/inbox on `ready` and `notification.created`
- [x] Add focused stream/runtime tests where practical

## Phase 5 — Action Routing
- [x] Define per-type tap behavior and deep-link routing
- [x] Keep source business pages authoritative on current state/permissions
- [x] Add manual QA checklist per notification type

Manual QA checklist:
- [x] `VOID_APPROVAL_NEEDED` opens carts history on the notification date with `VOID_PENDING`
- [x] `VOID_APPROVED` opens carts history on the notification date with `VOIDED`
- [x] `VOID_REJECTED` opens carts history on the notification date with `FINALIZED`
- [x] `CASH_SESSION_CLOSED` opens closed-session detail when `sessionId` is available, otherwise cash history list
- [x] Opening a notification still marks it read and lets the destination page remain authoritative

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Assessment done |
| 1 | Complete | Models, API, repository, tests landed |
| 2 | Complete | Unread count + inbox controllers + tests landed |
| 3 | Complete | Route, inbox page, shared bell/badge, tests landed |
| 4 | Complete | SSE parser/client, runtime resource binding, reconnect/backoff, live inbox + badge updates |
| 5 | Complete | Type-to-route action mapping landed; notifications now open source business pages instead of acting as their own detail layer |
