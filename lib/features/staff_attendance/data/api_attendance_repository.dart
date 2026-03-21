import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_mapper.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_record_dto.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_shift_schedule_dto.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_api.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';

final apiAttendanceRepositoryProvider = Provider<ApiAttendanceRepository>((
  ref,
) {
  final api = ref.watch(staffAttendanceApiProvider);
  return ApiAttendanceRepository(api);
});

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._api);

  final StaffAttendanceApi _api;

  @override
  Future<AttendanceContext> getAttendanceContext({
    required String branchId,
  }) async {
    try {
      final data = await _api.getAttendanceContext(branchId: branchId);
      if (data == null) return const AttendanceContext.empty();
      return mapAttendanceContextData(data);
    } on DioError {
      return const AttendanceContext.empty();
    }
  }

  @override
  Future<AttendanceMutationResult> checkIn(
    AttendanceCheckInPayload payload,
  ) async {
    try {
      final data = await _api.checkInV1(
        payload.toJson(),
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'attendance.check_in',
            payload: payload.toJson(),
            intentId: payload.clientOpId,
            scope: IdempotencyScope.branch,
          ),
        ),
      );
      if (data == null) {
        throw const AttendanceRepositoryException(
          reasonCode: AttendanceReasonCodes.invalidRequest,
          message: 'Check-in request was not accepted.',
        );
      }
      return _mapMutation(data, fallbackStatus: 'CHECKED_IN');
    } on DioError catch (error) {
      throw _mapError(error, fallbackMessage: 'Failed to check in.');
    }
  }

  @override
  Future<AttendanceMutationResult> checkOut(
    AttendanceCheckOutPayload payload,
  ) async {
    try {
      final data = await _api.checkOutV1(
        payload.toJson(),
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'attendance.check_out',
            payload: payload.toJson(),
            intentId: payload.clientOpId,
            scope: IdempotencyScope.branch,
          ),
        ),
      );
      if (data == null) {
        throw const AttendanceRepositoryException(
          reasonCode: AttendanceReasonCodes.noActiveAttendance,
          message: 'No active attendance session found to check out.',
        );
      }
      return _mapMutation(data, fallbackStatus: 'CHECKED_OUT');
    } on DioError catch (error) {
      throw _mapError(error, fallbackMessage: 'Failed to check out.');
    }
  }

  @override
  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  ) async {
    final entries = await _api.fetchMyShiftSchedule(branchId: range.branchId);
    return entries.map(_mapScheduleEntry).toList();
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  ) async {
    final from = filters.from?.toUtc().toIso8601String();
    final to = filters.to?.toUtc().toIso8601String();

    final records = filters.selfOnly
        ? await _api.fetchMyAttendance(
            branchId: filters.branchId,
            from: from,
            to: to,
            limit: filters.limit,
            offset: filters.offset,
          )
        : await _api.fetchAllAttendance(
            branchId: filters.branchId,
            employeeId: filters.employeeId,
            from: from,
            to: to,
            limit: filters.limit,
            offset: filters.offset,
          );
    return records.map(_mapRecord).toList();
  }

  AttendanceRecord _mapRecord(AttendanceRecordDto dto) {
    return mapAttendanceRecordDto(dto);
  }

  AttendanceMutationResult _mapMutation(
    Map<String, dynamic> data, {
    required String fallbackStatus,
  }) {
    final nestedRecord = _parseMap(data['record']);
    final mappedRecord = nestedRecord != null
        ? _mapRecordDtoMap(nestedRecord)
        : null;
    final status = data['status']?.toString() ?? fallbackStatus;

    final attendanceId =
        _readString(data, 'attendance_id', fallbackKey: 'attendanceId') ??
        _readString(data, 'id') ??
        mappedRecord?.id ??
        '';

    return AttendanceMutationResult(
      attendanceId: attendanceId,
      status: status,
      locationResult: _parseLocationResult(
        _readString(data, 'location_result', fallbackKey: 'locationResult'),
      ),
      distanceM: _readDouble(data, 'distance_m', fallbackKey: 'distanceM'),
      allowedRadiusM: _readDouble(
        data,
        'allowed_radius_m',
        fallbackKey: 'allowedRadiusM',
      ),
      message: data['message']?.toString() ?? 'Attendance recorded.',
      reasonCode: _readString(data, 'reason_code', fallbackKey: 'reasonCode'),
      record: mappedRecord,
    );
  }

  AttendanceRecord _mapRecordDtoMap(Map<String, dynamic> data) {
    return mapAttendanceRecordData(data);
  }

  AttendanceShiftScheduleEntry _mapScheduleEntry(
    AttendanceShiftScheduleEntryDto dto,
  ) {
    return AttendanceShiftScheduleEntry(
      dayOfWeek: dto.dayOfWeek,
      startTime: dto.startTime,
      endTime: dto.endTime,
      isOff: dto.isOff,
    );
  }

  AttendanceLocationResult _parseLocationResult(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'MATCH':
        return AttendanceLocationResult.match;
      case 'MISMATCH':
        return AttendanceLocationResult.mismatch;
      default:
        return AttendanceLocationResult.unknown;
    }
  }

  AttendanceRepositoryException _mapError(
    DioError error, {
    required String fallbackMessage,
  }) {
    final data = _parseMap(error.response?.data);
    final nested = data == null ? null : _parseMap(data['data']);
    final source = nested ?? data ?? const <String, dynamic>{};
    return AttendanceRepositoryException(
      reasonCode:
          _readString(source, 'reason_code', fallbackKey: 'reasonCode') ??
          AttendanceReasonCodes.unknownError,
      message:
          _readString(source, 'message', fallbackKey: 'reason_message') ??
          fallbackMessage,
    );
  }

  Map<String, dynamic>? _parseMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return null;
  }

  String? _readString(
    Map<String, dynamic> map,
    String key, {
    String? fallbackKey,
  }) {
    final raw = map[key] ?? (fallbackKey == null ? null : map[fallbackKey]);
    final value = raw?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  double? _readDouble(
    Map<String, dynamic> map,
    String key, {
    String? fallbackKey,
  }) {
    final raw = map[key] ?? (fallbackKey == null ? null : map[fallbackKey]);
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }
}
