import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_sync_pull_consumer.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';

void main() {
  late AppDatabase database;
  late DriftAttendanceCacheStore cacheStore;
  late AttendanceSyncPullConsumer consumer;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cacheStore = DriftAttendanceCacheStore(database);
    consumer = AttendanceSyncPullConsumer(cacheStore);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'apply writes attendance context and records for active scope',
    () async {
      const scope = AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );

      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
        ),
        payload: const {
          'context': {
            'canCheckIn': true,
            'locationVerificationMode': 'checkinOnly',
            'activeShift': {
              'shiftId': 'shift-1',
              'startAt': '09:00',
              'endAt': '17:00',
            },
            'geofence': {
              'centerLat': 11.556,
              'centerLng': 104.928,
              'radiusM': 120,
            },
          },
          'records': [
            {
              'id': 'record-1',
              'tenantId': 'tenant-1',
              'branchId': 'branch-1',
              'employeeId': 'account-1',
              'type': 'CHECK_IN',
              'occurredAt': '2026-03-17T09:01:00Z',
              'createdAt': '2026-03-17T09:01:00Z',
              'location': {'lat': 11.556, 'lng': 104.928},
            },
          ],
        },
        cursor: 'cursor-1',
        pulledAt: DateTime.utc(2026, 3, 17, 17),
      );

      final cached = await cacheStore.read(scope);

      expect(cached.context, isNotNull);
      expect(cached.context!.canCheckIn, isTrue);
      expect(
        cached.context!.locationVerificationMode,
        AttendanceLocationVerificationMode.checkinOnly,
      );
      expect(cached.records, hasLength(1));
      expect(cached.records.single.id, 'record-1');
    },
  );

  test(
    'apply preserves cached records when payload only updates context',
    () async {
      const scope = AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );
      await cacheStore.writeRecords(
        scope: scope,
        records: [
          AttendanceRecord(
            id: 'record-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            employeeId: 'account-1',
            type: 'CHECK_IN',
            occurredAt: DateTime.utc(2026, 3, 17, 9, 1),
            createdAt: DateTime.utc(2026, 3, 17, 9, 1),
            location: const AttendanceLocation(lat: 11.556, lng: 104.928),
          ),
        ],
      );

      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
        ),
        payload: const {
          'context': {
            'canCheckIn': false,
            'reasonCode': 'ALREADY_CHECKED_IN',
            'activeAttendance': {
              'attendanceId': 'attendance-1',
              'startAt': '2026-03-17T09:01:00Z',
            },
            'locationVerificationMode': 'disabled',
          },
        },
        cursor: 'cursor-2',
        pulledAt: DateTime.utc(2026, 3, 17, 18),
      );

      final cached = await cacheStore.read(scope);

      expect(cached.context, isNotNull);
      expect(cached.context!.canCheckIn, isFalse);
      expect(cached.context!.reasonCode, 'ALREADY_CHECKED_IN');
      expect(cached.records, hasLength(1));
      expect(cached.records.single.id, 'record-1');
    },
  );

  test('apply requires branch and account context', () async {
    await expectLater(
      () => consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: '',
          accountId: '',
        ),
        payload: const {'context': {}},
        cursor: 'cursor-3',
        pulledAt: DateTime.utc(2026, 3, 17, 19),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
