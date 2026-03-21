import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/staff_attendance/data/api_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/mock_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:uuid/uuid.dart';

class UseMockAttendanceRepositoryNotifier extends Notifier<bool> {
  @override
  bool build() => AppEnv.useMockAttendanceRepository;

  void setMock(bool value) => state = value;
  void toggle() => state = !state;
}

final useMockAttendanceRepositoryProvider =
    NotifierProvider<UseMockAttendanceRepositoryNotifier, bool>(
      UseMockAttendanceRepositoryNotifier.new,
    );

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final useMock = ref.watch(useMockAttendanceRepositoryProvider);
  if (useMock) {
    return ref.watch(mockAttendanceRepositoryProvider);
  }
  return ref.watch(apiAttendanceRepositoryProvider);
});

final staffAttendanceRepositoryProvider = Provider<StaffAttendanceRepository>((
  ref,
) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final requestTimeout = ref.watch(attendanceRequestTimeoutProvider);
  return StaffAttendanceRepository(repository, requestTimeout: requestTimeout);
});

final attendanceRequestTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 12),
);

class StaffAttendanceRepository {
  static const Uuid _uuid = Uuid();

  StaffAttendanceRepository(
    this._repository, {
    this.requestTimeout = const Duration(seconds: 12),
  });

  final AttendanceRepository _repository;
  final Duration requestTimeout;

  Future<AttendanceContext> getAttendanceContext({
    required String branchId,
  }) async {
    return _withTimeout(_repository.getAttendanceContext(branchId: branchId));
  }

  Future<AttendanceMutationResult> checkInWithPayload(
    AttendanceCheckInPayload payload,
  ) async {
    return _withTimeout(_repository.checkIn(payload));
  }

  Future<AttendanceMutationResult> checkOutWithPayload(
    AttendanceCheckOutPayload payload,
  ) async {
    return _withTimeout(_repository.checkOut(payload));
  }

  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  ) async {
    return _withTimeout(_repository.getMySchedule(range));
  }

  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  ) async {
    return _withTimeout(_repository.getAttendanceRecords(filters));
  }

  Future<List<AttendanceRecord>> fetchAdminAttendance({
    String? branchId,
    String? employeeId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    return _withTimeout(
      _repository.getAttendanceRecords(
        AttendanceRecordsFilter(
          branchId: branchId,
          employeeId: employeeId,
          from: _parseIsoDate(from),
          to: _parseIsoDate(to),
          limit: limit,
          offset: offset,
          selfOnly: false,
        ),
      ),
    );
  }

  Future<List<AttendanceRecord>> fetchMyAttendance({
    String? branchId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    return _withTimeout(
      _repository.getAttendanceRecords(
        AttendanceRecordsFilter(
          branchId: branchId,
          from: _parseIsoDate(from),
          to: _parseIsoDate(to),
          limit: limit,
          offset: offset,
          selfOnly: true,
        ),
      ),
    );
  }

  Future<List<AttendanceShiftScheduleEntry>> fetchMyShiftSchedule({
    String? branchId,
  }) async {
    return _withTimeout(
      _repository.getMySchedule(AttendanceScheduleRange(branchId: branchId)),
    );
  }

  Future<AttendanceRecord?> checkIn({
    required String occurredAt,
    Map<String, num>? location,
    String? shiftStatus,
    int? earlyMinutes,
    String? note,
  }) async {
    final result = await _withTimeout(
      _repository.checkIn(
        AttendanceCheckInPayload(
          branchId: null,
          deviceLat: _readCoordinate(location, 'lat'),
          deviceLng: _readCoordinate(location, 'lng'),
          deviceAccuracyM: null,
          clientOpId: _buildClientOpId(),
          clientTs: occurredAt,
        ),
      ),
    );
    return result.record;
  }

  Future<AttendanceRecord?> checkOut({
    required String occurredAt,
    Map<String, num>? location,
  }) async {
    final result = await _withTimeout(
      _repository.checkOut(
        AttendanceCheckOutPayload(
          branchId: null,
          deviceLat: _readCoordinate(location, 'lat'),
          deviceLng: _readCoordinate(location, 'lng'),
          deviceAccuracyM: null,
          clientOpId: _buildClientOpId(),
          clientTs: occurredAt,
        ),
      ),
    );
    return result.record;
  }

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(requestTimeout);
  }

  DateTime? _parseIsoDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  double? _readCoordinate(Map<String, num>? location, String key) {
    final value = location?[key];
    if (value == null) return null;
    return value.toDouble();
  }

  String _buildClientOpId() {
    return _uuid.v4();
  }
}
