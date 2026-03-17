import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/dto/attendance_record_dto.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';

AttendanceContext mapAttendanceContextData(Map<String, dynamic> data) {
  final activeShift = _parseMap(data['active_shift'] ?? data['activeShift']);
  final activeAttendance = _parseMap(
    data['active_attendance'] ?? data['activeAttendance'],
  );
  final geofence = _parseMap(data['geofence']);
  return AttendanceContext(
    canCheckIn: data['can_check_in'] == true || data['canCheckIn'] == true,
    reasonCode: _readString(data, 'reason_code', fallbackKey: 'reasonCode'),
    reasonMessage: _readString(
      data,
      'reason_message',
      fallbackKey: 'reasonMessage',
    ),
    activeShift: activeShift == null
        ? null
        : AttendanceShiftWindow(
            shiftId:
                _readString(activeShift, 'shift_id', fallbackKey: 'shiftId') ??
                '',
            startAt:
                _readString(activeShift, 'start_at', fallbackKey: 'startAt') ??
                '',
            endAt:
                _readString(activeShift, 'end_at', fallbackKey: 'endAt') ?? '',
          ),
    activeAttendance: activeAttendance == null
        ? null
        : ActiveAttendanceSession(
            attendanceId:
                _readString(
                  activeAttendance,
                  'attendance_id',
                  fallbackKey: 'attendanceId',
                ) ??
                '',
            startAt:
                _readString(
                  activeAttendance,
                  'start_at',
                  fallbackKey: 'startAt',
                ) ??
                '',
          ),
    locationVerificationMode: parseAttendanceVerificationMode(
      _readString(
            data,
            'location_verification_mode',
            fallbackKey: 'locationVerificationMode',
          ) ??
          'disabled',
    ),
    geofence: geofence == null
        ? null
        : AttendanceGeofence(
            centerLat:
                _readDouble(geofence, 'center_lat', fallbackKey: 'centerLat') ??
                0,
            centerLng:
                _readDouble(geofence, 'center_lng', fallbackKey: 'centerLng') ??
                0,
            radiusM:
                _readDouble(geofence, 'radius_m', fallbackKey: 'radiusM') ?? 0,
          ),
  );
}

AttendanceRecord mapAttendanceRecordDto(AttendanceRecordDto dto) {
  AttendanceLocation? location;
  if (dto.location != null) {
    location = AttendanceLocation(
      lat: dto.location!.lat,
      lng: dto.location!.lng,
    );
  }
  return AttendanceRecord(
    id: dto.id,
    tenantId: dto.tenantId,
    branchId: dto.branchId,
    employeeId: dto.employeeId,
    type: dto.type,
    occurredAt: dto.occurredAt.toLocal(),
    createdAt: dto.createdAt.toLocal(),
    location: location,
  );
}

AttendanceRecord mapAttendanceRecordData(Map<String, dynamic> data) {
  return mapAttendanceRecordDto(AttendanceRecordDto.fromJson(data));
}

AttendanceLocationVerificationMode parseAttendanceVerificationMode(String raw) {
  switch (raw.toLowerCase()) {
    case 'checkin_only':
    case 'checkinonly':
      return AttendanceLocationVerificationMode.checkinOnly;
    case 'checkin_and_checkout':
    case 'checkinandcheckout':
      return AttendanceLocationVerificationMode.checkinAndCheckout;
    default:
      return AttendanceLocationVerificationMode.disabled;
  }
}

Map<String, dynamic>? _parseMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

String? _readString(
  Map<String, dynamic> data,
  String key, {
  String? fallbackKey,
}) {
  final value = data[key] ?? (fallbackKey == null ? null : data[fallbackKey]);
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? null : parsed;
}

double? _readDouble(
  Map<String, dynamic> data,
  String key, {
  String? fallbackKey,
}) {
  final value = data[key] ?? (fallbackKey == null ? null : data[fallbackKey]);
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed;
}
