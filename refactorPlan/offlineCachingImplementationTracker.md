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
- pull-sync orchestrator: not started
- offline queue / replay: not started

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
| Offline command queue | Replay-safe write queue / `sync/push` | Deferred | Not run | Explicitly out of current implementation scope |
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
- [sync_pull_orchestrator.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_orchestrator.dart)

### Policy pilot
- [policy_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/policy/data/policy_cache_store.dart)
- [policy_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/viewmodels/policy_viewmodel.dart)

### Cash session pilot
- [cash_session_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/data/cash_session_cache_store.dart)
- [cash_session_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart)

### Menu pilot
- [menu_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/menu/data/menu_cache_store.dart)
- [menu_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/menu/ui/viewmodels/menu_viewmodel.dart)

Sale dependency note:
- [sale_page.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale/sale_page.dart)
  reads menu through `menuViewModelProvider`, so the sale catalog already
  benefits from the cache-first menu bundle for the `branchContext` lane.
- This does **not** make sale fully offline-ready:
  - item-detail modifier hydration still uses live `loadItemWithModifiers(...)`
  - checkout/finalize remains online-dependent
  - KHQR remains strictly online-only

### Attendance pilot
- [attendance_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/data/attendance_cache_store.dart)
- [attendance_check_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_check/attendance_check_page.dart)
- [attendance_history_page.dart](/Users/mac/flutterProjects/modular/lib/features/staff_attendance/ui/view/attendance_history/attendance_history_page.dart)

### Shift pilot
- [staff_shift_cache_store.dart](/Users/mac/flutterProjects/modular/lib/features/staff/data/staff_shift_cache_store.dart)
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
- [sync_pull_orchestrator_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_pull_orchestrator_test.dart)
- [policy_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/policy/policy_cache_store_test.dart)
- [policy_notifier_test.dart](/Users/mac/flutterProjects/modular/test/policy/policy_notifier_test.dart)
- [cash_session_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_cache_store_test.dart)
- [cash_session_viewmodel_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_viewmodel_test.dart)
- [menu_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/menu/menu_cache_store_test.dart)
- [menu_viewmodel_test.dart](/Users/mac/flutterProjects/modular/test/menu/menu_viewmodel_test.dart)
- [attendance_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_cache_store_test.dart)
- [attendance_check_page_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_check_page_test.dart)
- [attendance_history_page_test.dart](/Users/mac/flutterProjects/modular/test/staff_attendance/attendance_history_page_test.dart)
- [staff_shift_cache_store_test.dart](/Users/mac/flutterProjects/modular/test/staff/staff_shift_cache_store_test.dart)
- [staff_shift_controller_test.dart](/Users/mac/flutterProjects/modular/test/staff/staff_shift_controller_test.dart)

---

## Next Recommended Slice

1. Shared convergence step after first-wave module rollout
- register real feature pull consumers on top of the generic orchestrator foundation

Reason:
- the generic orchestration layer now exists
- the next missing work is module-specific pull payload application into the existing caches

---

## Open Implementation Questions

1. Should `cashSession` land as one mixed-cache slice or be split into:
- active session snapshot first
- movements/history/sales second

2. Should the first orchestrator version be introduced before `menu`, or after `cashSession` proves the second module pattern?

3. Do we want a temporary feature flag around cache-first reads during the first two pilot modules?

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
| Pull-sync orchestrator | Validated | Generic foundation implemented; feature consumers still pending |
| Offline queue | Deferred | Separate milestone |
| Notifications/SSE | Deferred | Separate milestone |
