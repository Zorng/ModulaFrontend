import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_history/attendance_history_page.dart';

import '../test_utils/pump_app.dart';

void main() {
  testWidgets('shows cached attendance history while refresh is in flight', (
    tester,
  ) async {
    final cacheStore = _MemoryAttendanceCacheStore();
    final today = DateTime.now();
    await cacheStore.writeRecords(
      scope: const AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-1',
      ),
      records: [
        AttendanceRecord(
          id: 'record-2',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          employeeId: 'user-1',
          type: 'CHECK_OUT',
          occurredAt: DateTime(today.year, today.month, today.day, 17),
          createdAt: DateTime(today.year, today.month, today.day, 17),
        ),
        AttendanceRecord(
          id: 'record-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          employeeId: 'user-1',
          type: 'CHECK_IN',
          occurredAt: DateTime(today.year, today.month, today.day, 8),
          createdAt: DateTime(today.year, today.month, today.day, 8),
        ),
      ],
    );

    await pumpApp(
      tester,
      const AttendanceHistoryPage(),
      overrides: [
        attendanceCacheStoreProvider.overrideWithValue(cacheStore),
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(_session()),
        ),
        staffAttendanceRepositoryProvider.overrideWithValue(
          StaffAttendanceRepository(_PendingHistoryAttendanceRepository()),
        ),
      ],
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('${today.year}-'), findsOneWidget);
    expect(find.text('8:00 AM'), findsOneWidget);
    expect(find.text('5:00 PM'), findsOneWidget);
    await tester.pump(const Duration(seconds: 13));
  });

  testWidgets('keeps cached attendance history when refresh times out', (
    tester,
  ) async {
    final cacheStore = _MemoryAttendanceCacheStore();
    final today = DateTime.now();
    await cacheStore.writeRecords(
      scope: const AttendanceCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'user-1',
      ),
      records: [
        AttendanceRecord(
          id: 'record-2',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          employeeId: 'user-1',
          type: 'CHECK_OUT',
          occurredAt: DateTime(today.year, today.month, today.day, 17),
          createdAt: DateTime(today.year, today.month, today.day, 17),
        ),
        AttendanceRecord(
          id: 'record-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          employeeId: 'user-1',
          type: 'CHECK_IN',
          occurredAt: DateTime(today.year, today.month, today.day, 8),
          createdAt: DateTime(today.year, today.month, today.day, 8),
        ),
      ],
    );

    await pumpApp(
      tester,
      const AttendanceHistoryPage(),
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
            _PendingHistoryAttendanceRepository(),
            requestTimeout: const Duration(milliseconds: 10),
          ),
        ),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.textContaining('${today.year}-'), findsOneWidget);
    expect(find.text('Failed to load attendance history'), findsOneWidget);
  });
}

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

class _PendingHistoryAttendanceRepository implements AttendanceRepository {
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
  Future<AttendanceContext> getAttendanceContext({
    required String branchId,
  }) async {
    return const AttendanceContext.empty();
  }

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
