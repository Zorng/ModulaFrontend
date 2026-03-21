import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';

void main() {
  late AppDatabase database;
  late AttendanceCacheStore store;

  const scope = AttendanceCacheScope(
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'user-1',
  );

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftAttendanceCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'writes and reads cached attendance context and records by scope',
    () async {
      await store.writeContext(
        scope: scope,
        context: const AttendanceContext(
          canCheckIn: false,
          reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
          reasonMessage: 'Already working.',
          activeShift: AttendanceShiftWindow(
            shiftId: 'shift-1',
            startAt: '2026-03-16T01:00:00Z',
            endAt: '2026-03-16T09:00:00Z',
          ),
          activeAttendance: ActiveAttendanceSession(
            attendanceId: 'attendance-1',
            startAt: '2026-03-16T01:05:00Z',
          ),
          locationVerificationMode:
              AttendanceLocationVerificationMode.checkinAndCheckout,
          geofence: AttendanceGeofence(
            centerLat: 11.56,
            centerLng: 104.92,
            radiusM: 50,
          ),
        ),
      );
      await store.writeRecords(
        scope: scope,
        records: [
          AttendanceRecord(
            id: 'record-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            employeeId: 'user-1',
            type: 'CHECK_IN',
            occurredAt: DateTime.utc(2026, 3, 16, 1),
            createdAt: DateTime.utc(2026, 3, 16, 1),
            location: const AttendanceLocation(lat: 11.56, lng: 104.92),
          ),
        ],
      );

      final loaded = await store.read(scope);

      expect(loaded.context, isNotNull);
      expect(loaded.context!.activeAttendance!.attendanceId, 'attendance-1');
      expect(
        loaded.context!.locationVerificationMode,
        AttendanceLocationVerificationMode.checkinAndCheckout,
      );
      expect(loaded.records, hasLength(1));
      expect(loaded.records.single.id, 'record-1');
      expect(loaded.records.single.location, isNotNull);
    },
  );

  test('clear removes the targeted attendance cache scope only', () async {
    await store.writeContext(
      scope: scope,
      context: const AttendanceContext.empty(),
    );
    await store.writeRecords(
      scope: scope,
      records: [
        AttendanceRecord(
          id: 'record-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          employeeId: 'user-1',
          type: 'CHECK_IN',
          occurredAt: DateTime.utc(2026, 3, 16, 1),
          createdAt: DateTime.utc(2026, 3, 16, 1),
        ),
      ],
    );
    await store.writeContext(
      scope: const AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-2',
      ),
      context: const AttendanceContext.empty(),
    );

    await store.clear(scope);

    final cleared = await store.read(scope);
    final remaining = await store.read(
      const AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-2',
      ),
    );

    expect(cleared.context, isNull);
    expect(cleared.records, isEmpty);
    expect(remaining.context, isNotNull);
  });
}
