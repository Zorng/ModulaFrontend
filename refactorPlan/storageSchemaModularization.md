# Storage Schema Modularization

Goal: reduce the overload in `lib/core/storage/app_database.dart` by moving
feature-owned cache table definitions into their feature data layers while
keeping `AppDatabase` as the central database composition root.

## Why this cleanup is needed

Current problem:
- [app_database.dart](/Users/mac/flutterProjects/modular/lib/core/storage/app_database.dart)
  now contains:
  - shared database runtime wiring
  - every feature cache table definition
  - schema versioning
  - migration coordination

That file was acceptable for the first cache pilots, but it is now carrying too
much feature-specific schema detail and will get worse once pull-sync
orchestration is added.

## Locked design direction

### Core owns
- database connection and runtime
- central `AppDatabase`
- schema version
- migration coordination
- shared cross-feature tables such as sync checkpoints

### Features own
- cache table definitions
- cache queries / adapters
- row-to-domain mapping for feature cache reads

## Target structure

Examples:
- `lib/features/policy/data/policy_cache_tables.dart`
- `lib/features/cash_session/data/cash_session_cache_tables.dart`
- `lib/features/menu/data/menu_cache_tables.dart`
- `lib/features/staff_attendance/data/attendance_cache_tables.dart`
- `lib/features/staff/data/staff_shift_cache_tables.dart`

Then:
- [app_database.dart](/Users/mac/flutterProjects/modular/lib/core/storage/app_database.dart)
  becomes a thin composition file that imports those table files and registers
  them in `@DriftDatabase(...)`

## Non-goals

- no schema redesign
- no cache behavior changes
- no pull-sync orchestrator in this refactor
- no offline queue work

## Phase 0 — Inventory
- [x] List all current tables in `app_database.dart`
- [x] Classify each table as:
  - shared core table
  - feature-owned table
- [x] Lock final destination file for each feature table set

### Current table inventory

Shared core:
- `SyncCheckpointEntries`
  - stays in `lib/core/storage/app_database.dart`

Policy:
- `PolicyCacheEntries`
  - destination: `lib/features/policy/data/policy_cache_tables.dart`

Cash session:
- `CashSessionSnapshotEntries`
- `CashSessionMovementCacheEntries`
- `CashSessionSaleCacheEntries`
  - destination: `lib/features/cash_session/data/cash_session_cache_tables.dart`

Menu:
- `MenuCacheScopes`
- `MenuItemCacheEntries`
- `MenuCategoryCacheEntries`
- `MenuModifierGroupCacheEntries`
- `MenuBranchCacheEntries`
  - destination: `lib/features/menu/data/menu_cache_tables.dart`

Attendance:
- `AttendanceContextCacheEntries`
- `AttendanceRecordCacheEntries`
  - destination: `lib/features/staff_attendance/data/attendance_cache_tables.dart`

Shift:
- `StaffShiftScopeEntries`
- `StaffShiftBranchCacheEntries`
- `StaffShiftMembershipCacheEntries`
- `StaffShiftPatternCacheEntries`
- `StaffShiftInstanceCacheEntries`
  - destination: `lib/features/staff/data/staff_shift_cache_tables.dart`

## Phase 1 — Extract Feature Table Files
- [x] Move policy cache tables to policy data layer
- [x] Move cash-session cache tables to cash-session data layer
- [x] Move menu cache tables to menu data layer
- [x] Move attendance cache tables to staff-attendance data layer
- [x] Move shift cache tables to staff data layer

## Phase 2 — Thin AppDatabase
- [x] Update `app_database.dart` to import feature table files
- [x] Keep only:
  - `@DriftDatabase(...)`
  - `schemaVersion`
  - migrations
  - provider wiring

## Phase 3 — Regenerate + Validate
- [x] Regenerate Drift outputs
- [x] Run analyzer
- [x] Run focused cache-store/controller tests

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Ownership map locked |
| 1 | Completed | Feature table files created |
| 2 | Completed | `app_database.dart` reduced to composition root |
| 3 | Completed | Drift regenerated and focused cache suite passed |
