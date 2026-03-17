import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff/data/repository/staff_shift_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/attendance_check_page.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_geolocation.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_utils.dart';
import '../test_utils/pump_app.dart';

void main() {
  group('AttendanceCheckPage', () {
    testWidgets('shows one-time shift instance from canonical shift schedule', (
      tester,
    ) async {
      final today = DateTime.now();
      final session = _session();

      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          attendanceCacheStoreProvider.overrideWithValue(
            _MemoryAttendanceCacheStore(),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(session),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(_FakeAttendanceRepository()),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: StaffShiftSchedule(
                patterns: <StaffShiftPattern>[
                  StaffShiftPattern(
                    id: 'pattern-1',
                    tenantId: 'tenant-1',
                    membershipId: 'membership-1',
                    branchId: 'branch-1',
                    daysOfWeek: <int>[today.weekday % 7],
                    plannedStartTime: '08:00',
                    plannedEndTime: '17:00',
                    status: StaffShiftPatternStatus.active,
                    effectiveFrom: DateTime(
                      today.year,
                      today.month,
                      today.day,
                    ).subtract(const Duration(days: 1)),
                    effectiveTo: DateTime(
                      today.year,
                      today.month,
                      today.day,
                    ).add(const Duration(days: 1)),
                    note: null,
                    createdAt: today,
                    updatedAt: today,
                  ),
                ],
                instances: <StaffShiftInstance>[
                  StaffShiftInstance(
                    id: 'instance-1',
                    tenantId: 'tenant-1',
                    membershipId: 'membership-1',
                    branchId: 'branch-1',
                    patternId: null,
                    date: DateTime(today.year, today.month, today.day),
                    plannedStartTime: '14:00',
                    plannedEndTime: '22:00',
                    status: StaffShiftInstanceStatus.planned,
                    note: null,
                    createdAt: today,
                    updatedAt: today,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('14:00 - 22:00'), findsOneWidget);
      expect(find.text('One-time shift'), findsOneWidget);
      expect(find.text('No Shift Today'), findsNothing);
    });

    testWidgets('shows the next upcoming one-time shift instance', (
      tester,
    ) async {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          attendanceCacheStoreProvider.overrideWithValue(
            _MemoryAttendanceCacheStore(),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_session()),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(_FakeAttendanceRepository()),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: StaffShiftSchedule(
                patterns: <StaffShiftPattern>[
                  StaffShiftPattern(
                    id: 'pattern-1',
                    tenantId: 'tenant-1',
                    membershipId: 'membership-1',
                    branchId: 'branch-1',
                    daysOfWeek: <int>[today.weekday % 7],
                    plannedStartTime: '08:00',
                    plannedEndTime: '17:00',
                    status: StaffShiftPatternStatus.active,
                    effectiveFrom: DateTime(
                      today.year,
                      today.month,
                      today.day,
                    ).subtract(const Duration(days: 1)),
                    effectiveTo: DateTime(
                      today.year,
                      today.month,
                      today.day,
                    ).add(const Duration(days: 7)),
                    note: null,
                    createdAt: today,
                    updatedAt: today,
                  ),
                ],
                instances: <StaffShiftInstance>[
                  StaffShiftInstance(
                    id: 'instance-future',
                    tenantId: 'tenant-1',
                    membershipId: 'membership-1',
                    branchId: 'branch-1',
                    patternId: null,
                    date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
                    plannedStartTime: '12:00',
                    plannedEndTime: '18:00',
                    status: StaffShiftInstanceStatus.planned,
                    note: null,
                    createdAt: today,
                    updatedAt: today,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Recurring shift'), findsOneWidget);
      expect(find.text('Next one-time shift'), findsOneWidget);
      expect(find.text(formatDatePretty(tomorrow.toLocal())), findsOneWidget);
      expect(find.text('12:00 - 18:00'), findsOneWidget);
    });

    testWidgets('keeps check in enabled when no shift is assigned', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          attendanceCacheStoreProvider.overrideWithValue(
            _MemoryAttendanceCacheStore(),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_session()),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(_FakeAttendanceRepository()),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: const StaffShiftSchedule(
                patterns: <StaffShiftPattern>[],
                instances: <StaffShiftInstance>[],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No Shift Today'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check-in'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('queues check in offline and updates local attendance state', (
      tester,
    ) async {
      final cacheStore = _MemoryAttendanceCacheStore();
      final queueStore = _MemoryOfflineCommandQueueStore();
      final repo = _TrackingAttendanceRepository(
        context: const AttendanceContext.empty(),
        records: const <AttendanceRecord>[],
      );

      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          offlineCommandQueueStoreProvider.overrideWithValue(queueStore),
          appConnectivityStatusProvider.overrideWith(
            () => _StaticConnectivityStatusController(
              AppConnectivityStatus.offline,
            ),
          ),
          attendanceCacheStoreProvider.overrideWithValue(cacheStore),
          attendanceGeoCaptureProvider.overrideWithValue(
            () async => const AttendanceGeoSnapshot(
              latitude: 11.55,
              longitude: 104.92,
              accuracyM: 8,
            ),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_session()),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(repo),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: const StaffShiftSchedule(
                patterns: <StaffShiftPattern>[],
                instances: <StaffShiftInstance>[],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(FilledButton, 'Check-in'));
      await tester.pump();

      final queued = await queueStore.listReplayReadyForContext(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-1',
      );
      final cached = await cacheStore.read(
        const AttendanceCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
      );

      expect(repo.checkInCalls, 0);
      expect(repo.checkOutCalls, 0);
      expect(queued, hasLength(1));
      expect(
        queued.single.operationType,
        OfflineOperationType.attendanceStartWork,
      );
      expect(cached.context?.activeAttendance, isNotNull);
      expect(cached.records, hasLength(1));
      expect(cached.records.single.type, 'CHECK_IN');
      expect(cached.records.single.location?.lat, 11.55);
      expect(find.widgetWithText(FilledButton, 'Check-out'), findsOneWidget);
      expect(
        find.text('Check-in saved offline. It will sync when you reconnect.'),
        findsOneWidget,
      );
    });

    testWidgets('queues check out offline and clears local open attendance', (
      tester,
    ) async {
      final cacheStore = _MemoryAttendanceCacheStore();
      final now = DateTime.now();
      final scope = const AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-1',
      );
      await cacheStore.writeContext(
        scope: scope,
        context: const AttendanceContext(
          canCheckIn: false,
          reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
          reasonMessage: 'Already checked in.',
          activeShift: null,
          activeAttendance: ActiveAttendanceSession(
            attendanceId: 'attendance-1',
            startAt: '2026-03-16T01:00:00Z',
          ),
          locationVerificationMode: AttendanceLocationVerificationMode.disabled,
          geofence: null,
        ),
      );
      await cacheStore.writeRecords(
        scope: scope,
        records: [
          AttendanceRecord(
            id: 'record-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            employeeId: 'user-1',
            type: 'CHECK_IN',
            occurredAt: DateTime(now.year, now.month, now.day, 8),
            createdAt: DateTime(now.year, now.month, now.day, 8),
          ),
        ],
      );

      final queueStore = _MemoryOfflineCommandQueueStore();
      final repo = _TrackingAttendanceRepository(
        context: const AttendanceContext(
          canCheckIn: false,
          reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
          reasonMessage: 'Already checked in.',
          activeShift: null,
          activeAttendance: ActiveAttendanceSession(
            attendanceId: 'attendance-1',
            startAt: '2026-03-16T01:00:00Z',
          ),
          locationVerificationMode: AttendanceLocationVerificationMode.disabled,
          geofence: null,
        ),
        records: [
          AttendanceRecord(
            id: 'record-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            employeeId: 'user-1',
            type: 'CHECK_IN',
            occurredAt: DateTime(now.year, now.month, now.day, 8),
            createdAt: DateTime(now.year, now.month, now.day, 8),
          ),
        ],
      );

      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          offlineCommandQueueStoreProvider.overrideWithValue(queueStore),
          appConnectivityStatusProvider.overrideWith(
            () => _StaticConnectivityStatusController(
              AppConnectivityStatus.offline,
            ),
          ),
          attendanceCacheStoreProvider.overrideWithValue(cacheStore),
          attendanceGeoCaptureProvider.overrideWithValue(
            () async => const AttendanceGeoSnapshot.empty(),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_session()),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(repo),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: const StaffShiftSchedule(
                patterns: <StaffShiftPattern>[],
                instances: <StaffShiftInstance>[],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(FilledButton, 'Check-out'));
      await tester.pump();

      final queued = await queueStore.listReplayReadyForContext(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-1',
      );
      final cached = await cacheStore.read(scope);

      expect(repo.checkInCalls, 0);
      expect(repo.checkOutCalls, 0);
      expect(queued, hasLength(1));
      expect(
        queued.single.operationType,
        OfflineOperationType.attendanceEndWork,
      );
      expect(cached.context?.activeAttendance, isNull);
      expect(cached.records, hasLength(2));
      expect(cached.records.last.type, 'CHECK_OUT');
      expect(find.widgetWithText(FilledButton, 'Check-in'), findsOneWidget);
      expect(
        find.text('Check-out saved offline. It will sync when you reconnect.'),
        findsOneWidget,
      );
    });

    testWidgets('shows cached attendance state while refresh is in flight', (
      tester,
    ) async {
      final cacheStore = _MemoryAttendanceCacheStore();
      final now = DateTime.now();
      await cacheStore.writeContext(
        scope: const AttendanceCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        context: const AttendanceContext(
          canCheckIn: false,
          reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
          reasonMessage: 'Already checked in.',
          activeShift: null,
          activeAttendance: ActiveAttendanceSession(
            attendanceId: 'attendance-1',
            startAt: '2026-03-16T01:00:00Z',
          ),
          locationVerificationMode: AttendanceLocationVerificationMode.disabled,
          geofence: null,
        ),
      );
      await cacheStore.writeRecords(
        scope: const AttendanceCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        records: [
          AttendanceRecord(
            id: 'record-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            employeeId: 'user-1',
            type: 'CHECK_IN',
            occurredAt: DateTime(now.year, now.month, now.day, 8),
            createdAt: DateTime(now.year, now.month, now.day, 8),
          ),
        ],
      );

      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          attendanceCacheStoreProvider.overrideWithValue(cacheStore),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_session()),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(_PendingAttendanceRepository()),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: const StaffShiftSchedule(
                patterns: <StaffShiftPattern>[],
                instances: <StaffShiftInstance>[],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Check-out'), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
    });

    testWidgets('keeps cached attendance state when refresh times out', (
      tester,
    ) async {
      final cacheStore = _MemoryAttendanceCacheStore();
      final now = DateTime.now();
      await cacheStore.writeContext(
        scope: const AttendanceCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        context: const AttendanceContext(
          canCheckIn: false,
          reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
          reasonMessage: 'Already checked in.',
          activeShift: null,
          activeAttendance: ActiveAttendanceSession(
            attendanceId: 'attendance-1',
            startAt: '2026-03-16T01:00:00Z',
          ),
          locationVerificationMode: AttendanceLocationVerificationMode.disabled,
          geofence: null,
        ),
      );
      await cacheStore.writeRecords(
        scope: const AttendanceCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'user-1',
        ),
        records: [
          AttendanceRecord(
            id: 'record-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            employeeId: 'user-1',
            type: 'CHECK_IN',
            occurredAt: DateTime(now.year, now.month, now.day, 8),
            createdAt: DateTime(now.year, now.month, now.day, 8),
          ),
        ],
      );

      await pumpApp(
        tester,
        const AttendanceCheckPage(),
        overrides: [
          attendanceCacheStoreProvider.overrideWithValue(cacheStore),
          attendanceRequestTimeoutProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_session()),
          ),
          staffAttendanceRepositoryProvider.overrideWithValue(
            StaffAttendanceRepository(
              _PendingAttendanceRepository(),
              requestTimeout: const Duration(milliseconds: 10),
            ),
          ),
          staffShiftRepositoryProvider.overrideWithValue(
            _FakeStaffShiftRepository(
              schedule: const StaffShiftSchedule(
                patterns: <StaffShiftPattern>[],
                instances: <StaffShiftInstance>[],
              ),
            ),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check-out'),
      );
      expect(button.onPressed, isNotNull);
      expect(find.text('Failed to load today attendance'), findsOneWidget);
    });
  });
}

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

class _FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceMutationResult> checkIn(
    AttendanceCheckInPayload payload,
  ) async {
    return AttendanceMutationResult(
      attendanceId: 'check-in-1',
      status: 'CHECKED_IN',
      locationResult: AttendanceLocationResult.unknown,
      distanceM: null,
      allowedRadiusM: null,
      message: 'Attendance recorded.',
      reasonCode: null,
      record: AttendanceRecord(
        id: 'check-in-1',
        tenantId: 'tenant-1',
        branchId: payload.branchId ?? 'branch-1',
        employeeId: 'user-1',
        type: 'CHECK_IN',
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<AttendanceMutationResult> checkOut(
    AttendanceCheckOutPayload payload,
  ) async {
    return AttendanceMutationResult(
      attendanceId: 'check-out-1',
      status: 'CHECKED_OUT',
      locationResult: AttendanceLocationResult.unknown,
      distanceM: null,
      allowedRadiusM: null,
      message: 'Attendance recorded.',
      reasonCode: null,
      record: AttendanceRecord(
        id: 'check-out-1',
        tenantId: 'tenant-1',
        branchId: payload.branchId ?? 'branch-1',
        employeeId: 'user-1',
        type: 'CHECK_OUT',
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<AttendanceContext> getAttendanceContext({
    required String branchId,
  }) async {
    return const AttendanceContext.empty();
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  ) async {
    return const <AttendanceRecord>[];
  }

  @override
  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  ) async {
    return const <AttendanceShiftScheduleEntry>[];
  }
}

class _PendingAttendanceRepository implements AttendanceRepository {
  final Completer<AttendanceContext> _contextCompleter =
      Completer<AttendanceContext>();
  final Completer<List<AttendanceRecord>> _recordsCompleter =
      Completer<List<AttendanceRecord>>();

  @override
  Future<AttendanceMutationResult> checkIn(
    AttendanceCheckInPayload payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceMutationResult> checkOut(
    AttendanceCheckOutPayload payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceContext> getAttendanceContext({required String branchId}) =>
      _contextCompleter.future;

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  ) => _recordsCompleter.future;

  @override
  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  ) async {
    return const <AttendanceShiftScheduleEntry>[];
  }
}

class _TrackingAttendanceRepository implements AttendanceRepository {
  _TrackingAttendanceRepository({
    required AttendanceContext context,
    required List<AttendanceRecord> records,
  }) : _context = context,
       _records = records;

  final AttendanceContext _context;
  final List<AttendanceRecord> _records;
  int checkInCalls = 0;
  int checkOutCalls = 0;

  @override
  Future<AttendanceMutationResult> checkIn(
    AttendanceCheckInPayload payload,
  ) async {
    checkInCalls += 1;
    throw UnimplementedError();
  }

  @override
  Future<AttendanceMutationResult> checkOut(
    AttendanceCheckOutPayload payload,
  ) async {
    checkOutCalls += 1;
    throw UnimplementedError();
  }

  @override
  Future<AttendanceContext> getAttendanceContext({
    required String branchId,
  }) async {
    return _context;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  ) async {
    return List<AttendanceRecord>.from(_records);
  }

  @override
  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  ) async {
    return const <AttendanceShiftScheduleEntry>[];
  }
}

class _MemoryAttendanceCacheStore implements AttendanceCacheStore {
  final Map<AttendanceCacheScope, AttendanceContext> _contexts =
      <AttendanceCacheScope, AttendanceContext>{};
  final Map<AttendanceCacheScope, List<AttendanceRecord>> _records =
      <AttendanceCacheScope, List<AttendanceRecord>>{};

  @override
  Future<void> clear(AttendanceCacheScope scope) async {
    _contexts.remove(scope);
    _records.remove(scope);
  }

  @override
  Future<AttendanceCacheSnapshot> read(AttendanceCacheScope scope) async {
    return AttendanceCacheSnapshot(
      context: _contexts[scope],
      records: List<AttendanceRecord>.from(_records[scope] ?? const []),
    );
  }

  @override
  Future<void> writeContext({
    required AttendanceCacheScope scope,
    required AttendanceContext context,
  }) async {
    _contexts[scope] = context;
  }

  @override
  Future<void> writeRecords({
    required AttendanceCacheScope scope,
    required List<AttendanceRecord> records,
  }) async {
    _records[scope] = List<AttendanceRecord>.from(records);
  }
}

class _StaticConnectivityStatusController
    extends AppConnectivityStatusController {
  _StaticConnectivityStatusController(this._status);

  final AppConnectivityStatus _status;

  @override
  AppConnectivityStatus build() => _status;
}

class _MemoryOfflineCommandQueueStore implements OfflineCommandQueueStore {
  final Map<String, OfflineCommandRecord> _records =
      <String, OfflineCommandRecord>{};

  @override
  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  }) async {
    return (await listForContext(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      statuses: statuses,
    )).length;
  }

  @override
  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  }) async {
    final normalizedStatuses = statuses ?? OfflineCommandQueueStatus.values.toSet();
    final filtered = _records.values
        .where(
          (record) =>
              record.tenantId == tenantId &&
              record.branchId == (branchId ?? '') &&
              record.accountId == (accountId ?? '') &&
              normalizedStatuses.contains(record.status),
        )
        .toList(growable: false)
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    if (filtered.length <= limit) return filtered;
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<List<OfflineCommandRecord>> listReplayReadyForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    int limit = 100,
  }) {
    return listForContext(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
      },
      limit: limit,
    );
  }

  @override
  Future<OfflineCommandRecord?> read(String clientOpId) async {
    return _records[clientOpId];
  }

  @override
  Future<void> write(OfflineCommandRecord record) async {
    _records[record.clientOpId] = record;
  }
}

class _FakeStaffShiftRepository implements StaffShiftRepository {
  _FakeStaffShiftRepository({required this.schedule});

  final StaffShiftSchedule schedule;

  @override
  Future<StaffShiftInstance> cancelInstance({
    required String instanceId,
    required String reason,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftInstance> createInstance({
    required String membershipId,
    required String branchId,
    required DateTime date,
    required String plannedStartTime,
    required String plannedEndTime,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftPattern> createPattern({
    required String membershipId,
    required String branchId,
    required List<int> daysOfWeek,
    required String plannedStartTime,
    required String plannedEndTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftPattern> deactivatePattern({
    required String patternId,
    required String reason,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftSchedule> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
  }) async {
    return schedule;
  }

  @override
  Future<StaffShiftSchedule> fetchMySchedule() async {
    return schedule;
  }

  @override
  Future<StaffShiftInstance> updateInstance({
    required String instanceId,
    DateTime? date,
    String? plannedStartTime,
    String? plannedEndTime,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftPattern> updatePattern({
    required String patternId,
    List<int>? daysOfWeek,
    String? plannedStartTime,
    String? plannedEndTime,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }
}

AuthSession _session() {
  final now = DateTime.now().toUtc();
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Cashier User',
      role: 'cashier',
      tenantId: 'tenant-1',
      branches: const <UserBranch>[
        UserBranch(
          id: 'assignment-1',
          branchId: 'branch-1',
          name: 'Main Branch',
          role: 'CASHIER',
          active: true,
        ),
      ],
    ),
    memberships: const <TenantMembership>[
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant One',
        role: 'CASHIER',
        branches: <UserBranch>[
          UserBranch(
            id: 'assignment-1',
            branchId: 'branch-1',
            name: 'Main Branch',
            role: 'CASHIER',
            active: true,
          ),
        ],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'token',
    refreshToken: 'refresh',
    accessTokenExpiresAt: now.add(const Duration(hours: 1)),
    refreshTokenExpiresAt: now.add(const Duration(days: 7)),
  );
}
