# Offline Caching Implementation Tracker

Goal: track the **actual implementation progress** of the offline caching rollout after the architecture plan was locked in [offlineCachingFoundation.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingFoundation.md).

Use this document for:
- current implementation status
- completed slices
- validation status
- next steps and blockers

Do not use this document for:
- revisiting architecture decisions already locked in the foundation plan
- feature redesign debates unless implementation exposes a real gap

---

## Current Position

Planning status:
- architecture planning is complete in [offlineCachingFoundation.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingFoundation.md)

Implementation status:
- first infrastructure slice is implemented
- first pilot module (`policy`) is implemented as cache-first
- first attendance pilot is now implemented as cache-first

Practical summary:
- shared storage foundation: started
- checkpoint persistence: started
- `policy` cache-first pilot: done
- `cashSession` cache-first pilot: done
- `menu` cache-first pilot: done
- `attendance` cache-first pilot: done
- `shift` cache-first pilot: done
- remaining first-wave modules: complete
- pull-sync orchestrator: generic foundation done, real consumers wired
- automatic `sync/pull` triggers: done for hydration, tenant switch, branch switch, reconnect
- shared freshness surfacing: first passive rollout done
- offline queue / replay: foundation started

---

## Status Legend

- `Not started`
- `In progress`
- `Implemented`
- `Validated`
- `Deferred`

---

## Workstreams

| Workstream | Scope | Status | Validation | Notes |
|---|---|---|---|---|
| Storage foundation | Shared local DB core under `lib/core/storage/` | Implemented | Analyzer passed | Uses `drift` with conditional native/web connections |
| Web DB runtime | `sqlite3.wasm` + `drift_worker.js` wiring | Implemented | Build artifacts created | Required for Drift persistence on web |
| Checkpoint persistence | Shared checkpoint store under `lib/core/sync/` | Validated | Unit tests passed | Ready for future pull-sync orchestration |
| Policy cache store | Branch-scoped snapshot cache | Validated | Unit tests passed | First cache adapter pilot |
| Policy cache-first read flow | Cached render first, remote refresh second | Validated | Unit tests passed | Implemented in `PolicyNotifier` |
| Cash session cache-first | Active session snapshot + loaded movements/sales cache | Validated | Analyzer + focused tests passed | Mixed-cache pilot started with active branch session flow |
| Menu cache-first | Scope-keyed normalized catalog cache | Validated | Analyzer + focused tests passed | `loadMenu()` now renders cached bundle first, then refreshes |
| Attendance cache-first | Mixed current-context + records cache | Validated | Analyzer + focused tests passed | `AttendanceCheckPage` and `AttendanceHistoryPage` now read cached state first |
| Shift cache-first | Normalized schedule cache | Validated | Analyzer + focused tests passed | Admin shift schedule now reads cached filter options and scoped schedule first |
| Pull-sync orchestrator | Shared `sync/pull` convergence layer | Validated | Analyzer + focused tests passed | Generic foundation landed with device ID, scope-set keying, transport, status, checkpoint-safe advancement, and pluggable consumers |
| Policy pull consumer | Policy payload application into local cache | Validated | Analyzer + focused tests passed | Parses defensive policy payload shapes, persists sync metadata, and is registered from `main.dart` |
| Cash session pull consumer | Cash-session snapshot application into local cache | Validated | Analyzer + focused tests passed | Applies defensive session bundles, preserves cached detail lists on partial payloads, clears cache on explicit no-active-session payloads, and is registered from `main.dart` |
| Menu pull consumer | Branch-context menu bundle application into local cache | Validated | Analyzer + focused tests passed | Hydrates the sale-facing `branchContext` cache for the active branch, preserves existing lists on partial payloads, and is registered from `main.dart` |
| Attendance pull consumer | Attendance context + record application into local cache | Validated | Analyzer + focused tests passed | Hydrates the active account/branch attendance cache, preserves cached records on context-only partial payloads, and is registered from `main.dart` |
| Shift pull consumer | Tenant options + scoped schedule application into local cache | Validated | Analyzer + focused tests passed | Hydrates tenant-wide branch/membership options and writes scoped schedules only when pull payload includes explicit range metadata |
| Automatic `sync/pull` triggers | Hydration, tenant switch, branch switch, reconnect | Validated | Analyzer + focused tests passed | Reuses the trigger controller and connectivity seam with cooldown/in-flight dedupe |
| Shared freshness surfacing | Passive syncing/stale/refresh-failed status | Validated | Analyzer + focused tests passed | Now integrated into policy, cash-session, and the main menu management page |
| Offline queue storage | Durable replay-safe queue rows under `lib/core/sync/` | Validated | Analyzer + focused tests passed | Drift-backed queue table + store landed with per-context filtering and replay-ready listing |
| Sync push transport | Shared `sync/push` transport + result mapping | Validated | Analyzer + focused tests passed | Defensive parser handles `APPLIED`, `DUPLICATE`, and `FAILED` result shapes |
| Sync push coordinator | Batched replay + post-push convergence trigger | Validated | Analyzer + focused tests passed | Replays pending rows for the active context, marks terminal statuses, and runs `sync/pull` after successful replay batches |
| Offline command queue feature integration | Cash-session + attendance enqueue policies | Validated | Analyzer + focused tests passed | Cash-session and attendance replay-safe writes now queue when offline with optimistic local UI/cache updates |
| Offline queue reconnect/manual flush | Replay lifecycle wiring | Validated | Analyzer + focused tests passed | Reconnect now replays queued writes first and only falls back to `sync/pull` when no pending queue exists; manual flush has a shared trigger seam with cooldown bypass |
| Notifications/SSE | Operational notifications | Deferred | Not run | Intentionally later |

---

## Implemented Artifacts

### Shared infrastructure
- [app_database.dart](/Users/mac/flutterProjects/modular/lib/core/storage/app_database.dart)
- [app_database.g.dart](/Users/mac/flutterProjects/modular/lib/core/storage/app_database.g.dart)
- [database_connection.dart](/Users/mac/flutterProjects/modular/lib/core/storage/database_connection.dart)
- [database_connection_native.dart](/Users/mac/flutterProjects/modular/lib/core/storage/database_connection_native.dart)
- [database_connection_web.dart](/Users/mac/flutterProjects/modular/lib/core/storage/database_connection_web.dart)
- [database_connection_stub.dart](/Users/mac/flutterProjects/modular/lib/core/storage/database_connection_stub.dart)
- [sync_checkpoint_store.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_checkpoint_store.dart)
- [sync_device_id_store.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_device_id_store.dart)
- [sync_models.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_models.dart)
- [sync_pull_api.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_api.dart)
- [sync_pull_trigger_controller.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_trigger_controller.dart)
- [sync_pull_orchestrator.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_orchestrator.dart)
- [offline_command_queue_tables.dart](/Users/mac/flutterProjects/modular/lib/core/sync/offline_command_queue_tables.dart)
- [offline_command_queue_store.dart](/Users/mac/flutterProjects/modular/lib/core/sync/offline_command_queue_store.dart)
- [sync_push_api.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_push_api.dart)
- [sync_push_coordinator.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_push_coordinator.dart)
- [sync_push_trigger_controller.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_push_trigger_controller.dart)
- [sync_freshness.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_freshness.dart)
- [app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)
- [app_connectivity.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity.dart)
- [sync_freshness_banner.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/sync/sync_freshness_banner.dart)
- [main.dart](/Users/mac/flutterProjects/modular/lib/main.dart)

### Policy pilot
- [policy_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/policy/data/policy_cache_store.dart)
- [policy_mapper.dart](/Users/mac/flutterProjects/modular/lib/features/policy/data/policy_mapper.dart)
- [policy_sync_pull_consumer.dart](/Users/mac/flutterProjects/modular/lib/features/policy/data/policy_sync_pull_consumer.dart)
- [policy_page.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/view/policy/policy_page.dart)
- [policy_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/viewmodels/policy_viewmodel.dart)

### Cash session pilot
- [cash_session_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/data/cash_session_cache_store.dart)
- [cash_session_mapper.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/data/cash_session_mapper.dart)
- [cash_session_offline_queue.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/data/cash_session_offline_queue.dart)
- [cash_session_sync_pull_consumer.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/data/cash_session_sync_pull_consumer.dart)
- [cashier_cash_session.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/cash_session/cashier_cash_session.dart)
- [cash_session_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart)

### Menu pilot
- [menu_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/menu/data/menu_cache_store.dart)
- [menu_sync_pull_consumer.dart](/Users/mac/flutterProjects/modular/lib/features/menu/data/menu_sync_pull_consumer.dart)
- [menu_page.dart](/Users/mac/flutterProjects/modular/lib/features/menu/ui/view/menu/menu_page.dart)
- [menu_page_items_section.dart](/Users/mac/flutterProjects/modular/lib/features/menu/ui/view/menu/widgets/menu_page_items_section.dart)
- [menu_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/menu/ui/viewmodels/menu_viewmodel.dart)

Sale dependency note:
- [sale_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale/sale_page.dart)
  reads menu through `menuViewModelProvider`, so the sale catalog already
  benefits from the cache-first menu bundle for the `branchContext` lane.
- The sale catalog now also surfaces the shared passive freshness banner when
  cached branch-context menu data is being shown during sync/offline failure.
- Backend scope update:
  - outage sale support is now **order-first**, not full offline settlement
  - outage non-cash fallback should use `MANUAL_EXTERNAL_PAYMENT_CLAIM`
  - backend now supports a dedicated manual-claim lane:
    - `POST /v0/orders` with `sourceMode = MANUAL_EXTERNAL_PAYMENT_CLAIM`
    - order claim list/create/approve/reject endpoints
  - `saleAllowManualExternalPaymentClaim` is separate from `saleAllowPayLater`
  - `sale.finalize` is still online-only
  - KHQR remains strictly online-only
- This still does **not** make sale fully offline-ready:
  - item-detail modifier hydration still uses live `loadItemWithModifiers(...)`
  - current cart checkout still goes straight to finalization when online
  - `placeOrder(...)` in [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart) is still unimplemented
  - first shipped outage slice is now implemented for **offline cash capture**:
    - durable sale outage store
    - offline cash cart action intercept
    - Orders projection for local outage orders
    - locally captured cash outage orders can now be finalized online from order detail through an explicit recovery action
  - next outage slice is now implemented for **local manual-claim capture/review**:
    - offline QR cart action can capture a manual-claim outage order when policy allows
    - policy/cache stack now reads `saleAllowManualExternalPaymentClaim`
    - outage orders can record local KHQR claim metadata on order detail
    - Orders projection now distinguishes manual-claim outage state from ordinary unpaid tickets
  - backend order materialization and claim submission/approve/reject are still not implemented in frontend
  - sale outage reconnect materialization is still not implemented in frontend
  - KHQR remains strictly online-only
- Follow-up planning artifact:
  - [saleOfflineOrderFirst.md](/Users/mac/flutterProjects/modular/refactorPlan/saleOfflineOrderFirst.md)

### Attendance pilot
- [attendance_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/attendance_cache_store.dart)
- [attendance_offline_queue.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/attendance_offline_queue.dart)
- [attendance_mapper.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/attendance_mapper.dart)
- [attendance_sync_pull_consumer.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/attendance_sync_pull_consumer.dart)
- [attendance_check_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_check/attendance_check_page.dart)
- [attendance_history_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_history/attendance_history_page.dart)

### Shift pilot
- [staff_shift_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/staff/data/staff_shift_cache_store.dart)
- [staff_shift_mapper.dart](/Users/mac/flutterProjects/modular/lib/features/staff/data/staff_shift_mapper.dart)
- [staff_shift_sync_pull_consumer.dart](/Users/mac/flutterProjects/modular/lib/features/staff/data/staff_shift_sync_pull_consumer.dart)
- [staff_shift_controller.dart](/Users/mac/flutterProjects/modular/lib/features/staff/ui/viewmodels/staff_shift_controller.dart)

### Web runtime files
- [drift_worker.dart](/Users/mac/flutterProjects/modular/web/drift_worker.dart)
- [drift_worker.js](/Users/mac/flutterProjects/modular/web/drift_worker.js)
- [sqlite3.wasm](/Users/mac/flutterProjects/modular/web/sqlite3.wasm)

---

## Validation Completed

Analyzer:
- `flutter analyze lib/core/storage/app_database.dart lib/core/storage/app_database.g.dart lib/core/storage/database_connection.dart lib/core/storage/database_connection_native.dart lib/core/storage/database_connection_stub.dart lib/core/storage/database_connection_web.dart lib/core/sync/sync_checkpoint_store.dart lib/features/policy/data/policy_cache_store.dart lib/features/policy/ui/viewmodels/policy_viewmodel.dart test/core/sync/sync_checkpoint_store_test.dart test/policy/policy_cache_store_test.dart test/policy/policy_notifier_test.dart`

Tests:
- `flutter test test/core/sync/sync_checkpoint_store_test.dart test/policy/policy_cache_store_test.dart test/policy/policy_notifier_test.dart`

Focused test files:
- [sync_checkpoint_store_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_checkpoint_store_test.dart)
- [sync_device_id_store_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_device_id_store_test.dart)
- [sync_models_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_models_test.dart)
- [sync_freshness_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_freshness_test.dart)
- [offline_command_queue_store_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/offline_command_queue_store_test.dart)
- [sync_push_api_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_push_api_test.dart)
- [sync_push_coordinator_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_push_coordinator_test.dart)
- [sync_pull_orchestrator_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_pull_orchestrator_test.dart)
- [sync_pull_trigger_controller_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_pull_trigger_controller_test.dart)
- [app_hydration_listener_test.dart](/Users/mac/flutterProjects/modular/test/core/hydration/app_hydration_listener_test.dart)
- [app_connectivity_test.dart](/Users/mac/flutterProjects/modular/test/core/network/app_connectivity_test.dart)
- [policy_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/policy/policy_cache_store_test.dart)
- [policy_notifier_test.dart](/Users/mac/flutterProjects/modular/test/policy/policy_notifier_test.dart)
- [policy_sync_pull_consumer_test.dart](/Users/mac/flutterProjects/modular/test/policy/policy_sync_pull_consumer_test.dart)
- [cash_session_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_cache_store_test.dart)
- [cash_session_sync_pull_consumer_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_sync_pull_consumer_test.dart)
- [cash_session_screen_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_screen_test.dart)
- [cash_session_viewmodel_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_viewmodel_test.dart)
- [cash_session_error_message_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_error_message_test.dart)
- [menu_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/menu/menu_cache_store_test.dart)
- [menu_page_test.dart](/Users/mac/flutterProjects/modular/test/menu/menu_page_test.dart)
- [menu_viewmodel_test.dart](/Users/mac/flutterProjects/modular/test/menu/menu_viewmodel_test.dart)
- [menu_sync_pull_consumer_test.dart](/Users/mac/flutterProjects/modular/test/menu/menu_sync_pull_consumer_test.dart)
- [attendance_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_cache_store_test.dart)
- [attendance_check_page_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_check_page_test.dart)
- [attendance_history_page_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_history_page_test.dart)
- [attendance_sync_pull_consumer_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_sync_pull_consumer_test.dart)
- [staff_shift_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/staff/staff_shift_cache_store_test.dart)
- [staff_shift_controller_test.dart](/Users/mac/flutterProjects/modular/test/staff/staff_shift_controller_test.dart)
- [staff_shift_sync_pull_consumer_test.dart](/Users/mac/flutterProjects/modular/test/staff/staff_shift_sync_pull_consumer_test.dart)

---

## Next Recommended Slice

1. Post-trigger validation and refinement
- broaden manual QA around branch switch, reconnect, and stale-cache surfacing
- decide whether the next UX slice should expand passive freshness surfacing beyond `policy` and `cashSession`

Reason:
- the generic orchestration layer now exists
- the first-wave module-specific pull payload application is wired end to end
- automatic convergence triggers and the first passive freshness surfaces are now live
- the next missing work is manual QA for offline -> reconnect behavior, then broader UX refinement around queue/push status

---

## Open Implementation Questions

1. Which app lifecycle points should trigger automatic `sync/pull` first:
- app hydration after login
- tenant switch
- branch switch
- reconnect

2. Do we want an initial conservative scope-set strategy per trigger, or always request the full first-wave module set?

3. Do we want a temporary feature flag around orchestrated pull triggering during the first live rollout?

---

## Tracking

| Item | Status | Notes |
|---|---|---|
| Foundation plan | Completed | Architecture locked in `offlineCachingFoundation.md` |
| Storage core | Implemented | Shared `drift` DB added |
| Checkpoint store | Validated | Unit-tested |
| Policy cache adapter | Validated | Unit-tested |
| Policy cache-first load | Validated | Cache-first read flow implemented |
| Cash session pilot | Validated | Active session + loaded movement/sales cache-first flow implemented |
| Menu pilot | Validated | Cache-first bundle load implemented |
| Attendance pilot | Validated | Check page + history page now render cached state first |
| Shift pilot | Validated | Cache-first load now covers filter options + scoped schedule |
| Pull-sync orchestrator | Validated | Generic foundation implemented; first-wave consumers (`policy`, `cashSession`, `menu`, `attendance`, `shift`) are wired |
| Automatic trigger rollout | Validated | Hydration, tenant switch, branch switch, and reconnect are wired through the trigger controller |
| Shared freshness rollout | Validated | Passive workspace syncing/stale/refresh-failed state now surfaces in policy, cash-session, and the main menu page |
| Policy pull consumer | Validated | Registered from `main.dart` and writes sync metadata into the cache |
| Cash session pull consumer | Validated | Registered from `main.dart`; applies bundle payloads and explicit clear semantics |
| Menu pull consumer | Validated | Registered from `main.dart`; hydrates branch-context menu cache for sale |
| Attendance pull consumer | Validated | Registered from `main.dart`; hydrates active account/branch attendance cache |
| Shift pull consumer | Validated | Registered from `main.dart`; hydrates tenant options and scoped schedules when payload supplies range metadata |
| Offline queue foundation | Validated | Queue store, push transport, and replay coordinator are now in place |
| Offline queue feature integration | Validated | Cash-session and attendance are integrated |
| Offline queue replay lifecycle | Validated | Reconnect replay + manual flush trigger seam are implemented; manual QA still pending |
| Notifications/SSE | Deferred | Separate milestone |
