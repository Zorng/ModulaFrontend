import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';

class AttendanceCacheScope {
  const AttendanceCacheScope({
    required this.tenantId,
    required this.branchId,
    required this.accountId,
  });

  final String tenantId;
  final String branchId;
  final String accountId;

  @override
  bool operator ==(Object other) {
    return other is AttendanceCacheScope &&
        other.tenantId == tenantId &&
        other.branchId == branchId &&
        other.accountId == accountId;
  }

  @override
  int get hashCode => Object.hash(tenantId, branchId, accountId);
}

class AttendanceCacheSnapshot {
  const AttendanceCacheSnapshot({required this.context, required this.records});

  final AttendanceContext? context;
  final List<AttendanceRecord> records;
}

abstract class AttendanceCacheStore {
  Future<AttendanceCacheSnapshot> read(AttendanceCacheScope scope);

  Future<void> writeContext({
    required AttendanceCacheScope scope,
    required AttendanceContext context,
  });

  Future<void> writeRecords({
    required AttendanceCacheScope scope,
    required List<AttendanceRecord> records,
  });

  Future<void> clear(AttendanceCacheScope scope);
}

class DriftAttendanceCacheStore implements AttendanceCacheStore {
  DriftAttendanceCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<AttendanceCacheSnapshot> read(AttendanceCacheScope scope) async {
    final contextRow =
        await (_db.select(_db.attendanceContextCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.branchId.equals(scope.branchId))
              ..where((tbl) => tbl.accountId.equals(scope.accountId)))
            .getSingleOrNull();
    final recordRows =
        await (_db.select(_db.attendanceRecordCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.branchId.equals(scope.branchId))
              ..where((tbl) => tbl.accountId.equals(scope.accountId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();

    return AttendanceCacheSnapshot(
      context: contextRow == null ? null : _mapContextRow(contextRow),
      records: recordRows.map(_mapRecordRow).toList(growable: false),
    );
  }

  @override
  Future<void> writeContext({
    required AttendanceCacheScope scope,
    required AttendanceContext context,
  }) {
    return _db
        .into(_db.attendanceContextCacheEntries)
        .insertOnConflictUpdate(
          AttendanceContextCacheEntriesCompanion.insert(
            tenantId: scope.tenantId,
            branchId: scope.branchId,
            accountId: scope.accountId,
            canCheckIn: context.canCheckIn,
            reasonCode: Value(context.reasonCode),
            reasonMessage: Value(context.reasonMessage),
            activeShiftId: Value(context.activeShift?.shiftId),
            activeShiftStartAt: Value(context.activeShift?.startAt),
            activeShiftEndAt: Value(context.activeShift?.endAt),
            activeAttendanceId: Value(context.activeAttendance?.attendanceId),
            activeAttendanceStartAt: Value(context.activeAttendance?.startAt),
            locationVerificationMode: context.locationVerificationMode.name,
            geofenceCenterLat: Value(context.geofence?.centerLat),
            geofenceCenterLng: Value(context.geofence?.centerLng),
            geofenceRadiusM: Value(context.geofence?.radiusM),
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> writeRecords({
    required AttendanceCacheScope scope,
    required List<AttendanceRecord> records,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.attendanceRecordCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.branchId.equals(scope.branchId))
            ..where((tbl) => tbl.accountId.equals(scope.accountId)))
          .go();

      for (var index = 0; index < records.length; index++) {
        final record = records[index];
        await _db
            .into(_db.attendanceRecordCacheEntries)
            .insert(
              AttendanceRecordCacheEntriesCompanion.insert(
                tenantId: scope.tenantId,
                branchId: scope.branchId,
                accountId: scope.accountId,
                recordId: record.id,
                employeeId: record.employeeId,
                type: record.type,
                occurredAt: record.occurredAt,
                createdAt: record.createdAt,
                locationLat: Value(record.location?.lat),
                locationLng: Value(record.location?.lng),
                sortOrder: index,
              ),
            );
      }
    });
  }

  @override
  Future<void> clear(AttendanceCacheScope scope) async {
    await _db.transaction(() async {
      await (_db.delete(_db.attendanceContextCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.branchId.equals(scope.branchId))
            ..where((tbl) => tbl.accountId.equals(scope.accountId)))
          .go();
      await (_db.delete(_db.attendanceRecordCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.branchId.equals(scope.branchId))
            ..where((tbl) => tbl.accountId.equals(scope.accountId)))
          .go();
    });
  }

  AttendanceContext _mapContextRow(AttendanceContextCacheEntry row) {
    final activeShiftId = row.activeShiftId;
    final activeAttendanceId = row.activeAttendanceId;
    final geofenceLat = row.geofenceCenterLat;
    final geofenceLng = row.geofenceCenterLng;
    final geofenceRadius = row.geofenceRadiusM;

    return AttendanceContext(
      canCheckIn: row.canCheckIn,
      reasonCode: row.reasonCode,
      reasonMessage: row.reasonMessage,
      activeShift: activeShiftId == null
          ? null
          : AttendanceShiftWindow(
              shiftId: activeShiftId,
              startAt: row.activeShiftStartAt ?? '',
              endAt: row.activeShiftEndAt ?? '',
            ),
      activeAttendance: activeAttendanceId == null
          ? null
          : ActiveAttendanceSession(
              attendanceId: activeAttendanceId,
              startAt: row.activeAttendanceStartAt ?? '',
            ),
      locationVerificationMode: _parseVerificationMode(
        row.locationVerificationMode,
      ),
      geofence:
          geofenceLat == null || geofenceLng == null || geofenceRadius == null
          ? null
          : AttendanceGeofence(
              centerLat: geofenceLat,
              centerLng: geofenceLng,
              radiusM: geofenceRadius,
            ),
    );
  }

  AttendanceRecord _mapRecordRow(AttendanceRecordCacheEntry row) {
    return AttendanceRecord(
      id: row.recordId,
      tenantId: row.tenantId,
      branchId: row.branchId,
      employeeId: row.employeeId,
      type: row.type,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
      location: row.locationLat == null || row.locationLng == null
          ? null
          : AttendanceLocation(lat: row.locationLat!, lng: row.locationLng!),
    );
  }

  AttendanceLocationVerificationMode _parseVerificationMode(String raw) {
    switch (raw.trim()) {
      case 'checkinOnly':
        return AttendanceLocationVerificationMode.checkinOnly;
      case 'checkinAndCheckout':
        return AttendanceLocationVerificationMode.checkinAndCheckout;
      case 'disabled':
      default:
        return AttendanceLocationVerificationMode.disabled;
    }
  }
}

final attendanceCacheScopeProvider = Provider<AttendanceCacheScope?>((ref) {
  final tenantId =
      (ref.watch(authTenantIdProvider) ??
              ref.watch(loginControllerProvider).session?.activeTenantId ??
              ref.watch(loginControllerProvider).session?.user.tenantId ??
              '')
          .trim();
  final branchId = (ref.watch(authActiveBranchIdProvider) ?? '').trim();
  final accountId = (ref.watch(loginControllerProvider).session?.user.id ?? '')
      .trim();

  if (tenantId.isEmpty || branchId.isEmpty || accountId.isEmpty) return null;
  return AttendanceCacheScope(
    tenantId: tenantId,
    branchId: branchId,
    accountId: accountId,
  );
});

final attendanceCacheStoreProvider = Provider<AttendanceCacheStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftAttendanceCacheStore(db);
});
