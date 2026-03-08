import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';

enum AttendanceLocationVerificationMode {
  disabled,
  checkinOnly,
  checkinAndCheckout,
}

enum AttendanceLocationResult { match, mismatch, unknown }

class AttendanceReasonCodes {
  static const noActiveShift = 'NO_ACTIVE_SHIFT';
  static const alreadyCheckedIn = 'ALREADY_CHECKED_IN';
  static const noActiveAttendance = 'NO_ACTIVE_ATTENDANCE';
  static const invalidRequest = 'INVALID_REQUEST';
  static const unknownError = 'UNKNOWN_ERROR';
}

class AttendanceShiftWindow {
  const AttendanceShiftWindow({
    required this.shiftId,
    required this.startAt,
    required this.endAt,
  });

  final String shiftId;
  final String startAt;
  final String endAt;
}

class ActiveAttendanceSession {
  const ActiveAttendanceSession({
    required this.attendanceId,
    required this.startAt,
  });

  final String attendanceId;
  final String startAt;
}

class AttendanceGeofence {
  const AttendanceGeofence({
    required this.centerLat,
    required this.centerLng,
    required this.radiusM,
  });

  final double centerLat;
  final double centerLng;
  final double radiusM;
}

class AttendanceContext {
  const AttendanceContext({
    required this.canCheckIn,
    required this.reasonCode,
    required this.reasonMessage,
    required this.activeShift,
    required this.activeAttendance,
    required this.locationVerificationMode,
    required this.geofence,
  });

  const AttendanceContext.empty()
    : canCheckIn = false,
      reasonCode = null,
      reasonMessage = null,
      activeShift = null,
      activeAttendance = null,
      locationVerificationMode = AttendanceLocationVerificationMode.disabled,
      geofence = null;

  final bool canCheckIn;
  final String? reasonCode;
  final String? reasonMessage;
  final AttendanceShiftWindow? activeShift;
  final ActiveAttendanceSession? activeAttendance;
  final AttendanceLocationVerificationMode locationVerificationMode;
  final AttendanceGeofence? geofence;
}

class AttendanceCheckInPayload {
  const AttendanceCheckInPayload({
    required this.branchId,
    required this.clientOpId,
    required this.clientTs,
    this.deviceLat,
    this.deviceLng,
    this.deviceAccuracyM,
  });

  final String? branchId;
  final double? deviceLat;
  final double? deviceLng;
  final double? deviceAccuracyM;
  final String clientOpId;
  final String clientTs;

  Map<String, dynamic> toJson() {
    final location = deviceLat == null || deviceLng == null
        ? null
        : <String, dynamic>{
            'latitude': deviceLat,
            'longitude': deviceLng,
            if (deviceAccuracyM != null) 'accuracyMeters': deviceAccuracyM,
            'capturedAt': clientTs,
          };
    return {'occurredAt': clientTs, if (location != null) 'location': location};
  }
}

class AttendanceCheckOutPayload {
  const AttendanceCheckOutPayload({
    required this.clientOpId,
    required this.clientTs,
    this.branchId,
    this.deviceLat,
    this.deviceLng,
    this.deviceAccuracyM,
  });

  final String? branchId;
  final double? deviceLat;
  final double? deviceLng;
  final double? deviceAccuracyM;
  final String clientOpId;
  final String clientTs;

  Map<String, dynamic> toJson() {
    final location = deviceLat == null || deviceLng == null
        ? null
        : <String, dynamic>{
            'latitude': deviceLat,
            'longitude': deviceLng,
            if (deviceAccuracyM != null) 'accuracyMeters': deviceAccuracyM,
            'capturedAt': clientTs,
          };
    return {'occurredAt': clientTs, if (location != null) 'location': location};
  }
}

class AttendanceMutationResult {
  const AttendanceMutationResult({
    required this.attendanceId,
    required this.status,
    required this.locationResult,
    required this.distanceM,
    required this.allowedRadiusM,
    required this.message,
    required this.reasonCode,
    required this.record,
  });

  final String attendanceId;
  final String status;
  final AttendanceLocationResult locationResult;
  final double? distanceM;
  final double? allowedRadiusM;
  final String message;
  final String? reasonCode;
  final AttendanceRecord? record;
}

class AttendanceScheduleRange {
  const AttendanceScheduleRange({this.branchId, this.from, this.to});

  final String? branchId;
  final DateTime? from;
  final DateTime? to;
}

class AttendanceRecordsFilter {
  const AttendanceRecordsFilter({
    this.branchId,
    this.employeeId,
    this.from,
    this.to,
    this.limit = 100,
    this.offset = 0,
    this.selfOnly = true,
  });

  final String? branchId;
  final String? employeeId;
  final DateTime? from;
  final DateTime? to;
  final int limit;
  final int offset;
  final bool selfOnly;
}

class AttendanceRepositoryException implements Exception {
  const AttendanceRepositoryException({
    required this.reasonCode,
    required this.message,
  });

  final String reasonCode;
  final String message;

  @override
  String toString() => 'AttendanceRepositoryException($reasonCode, $message)';
}

abstract class AttendanceRepository {
  Future<AttendanceContext> getAttendanceContext({required String branchId});

  Future<AttendanceMutationResult> checkIn(AttendanceCheckInPayload payload);

  Future<AttendanceMutationResult> checkOut(AttendanceCheckOutPayload payload);

  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  );

  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  );
}
