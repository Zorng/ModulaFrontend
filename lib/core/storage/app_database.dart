import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/offline_command_queue_tables.dart';
import 'package:modular_pos/core/storage/database_connection.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_cache_tables.dart';
import 'package:modular_pos/features/menu/data/menu_cache_tables.dart';
import 'package:modular_pos/features/policy/data/policy_cache_tables.dart';
import 'package:modular_pos/features/sale/data/sale_outage_cache_tables.dart';
import 'package:modular_pos/features/staff/data/staff_shift_cache_tables.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_tables.dart';

part 'app_database.g.dart';

class SyncCheckpointEntries extends Table {
  TextColumn get deviceId => text()();

  TextColumn get tenantId => text().withDefault(const Constant(''))();

  TextColumn get branchId => text().withDefault(const Constant(''))();

  TextColumn get accountId => text().withDefault(const Constant(''))();

  TextColumn get moduleScopeSetKey => text()();

  TextColumn get cursor => text().nullable()();

  DateTimeColumn get lastPullAt => dateTime().nullable()();

  DateTimeColumn get lastSuccessfulPullAt => dateTime().nullable()();

  TextColumn get lastPullStatus => text().nullable()();

  TextColumn get lastErrorCode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {
    deviceId,
    tenantId,
    branchId,
    accountId,
    moduleScopeSetKey,
  };
}

@DriftDatabase(
  tables: [
    SyncCheckpointEntries,
    OfflineCommandQueueEntries,
    SaleOutageOrderEntries,
    PolicyCacheEntries,
    CashSessionSnapshotEntries,
    CashSessionMovementCacheEntries,
    CashSessionSaleCacheEntries,
    MenuCacheScopes,
    MenuItemCacheEntries,
    MenuCategoryCacheEntries,
    MenuModifierGroupCacheEntries,
    MenuBranchCacheEntries,
    AttendanceContextCacheEntries,
    AttendanceRecordCacheEntries,
    StaffShiftScopeEntries,
    StaffShiftBranchCacheEntries,
    StaffShiftMembershipCacheEntries,
    StaffShiftPatternCacheEntries,
    StaffShiftInstanceCacheEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(openAppDatabaseConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cashSessionSnapshotEntries);
        await m.createTable(cashSessionMovementCacheEntries);
        await m.createTable(cashSessionSaleCacheEntries);
      }
      if (from < 3) {
        await m.createTable(menuCacheScopes);
        await m.createTable(menuItemCacheEntries);
        await m.createTable(menuCategoryCacheEntries);
        await m.createTable(menuModifierGroupCacheEntries);
        await m.createTable(menuBranchCacheEntries);
      }
      if (from < 4) {
        await m.createTable(attendanceContextCacheEntries);
        await m.createTable(attendanceRecordCacheEntries);
      }
      if (from < 5) {
        await m.createTable(staffShiftScopeEntries);
        await m.createTable(staffShiftBranchCacheEntries);
        await m.createTable(staffShiftMembershipCacheEntries);
        await m.createTable(staffShiftPatternCacheEntries);
        await m.createTable(staffShiftInstanceCacheEntries);
      }
      if (from < 6) {
        await m.createTable(offlineCommandQueueEntries);
      }
      if (from < 7) {
        await m.createTable(saleOutageOrderEntries);
      }
      if (from < 8) {
        await m.addColumn(
          policyCacheEntries,
          policyCacheEntries.saleAllowManualExternalPaymentClaim,
        );
      }
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});
