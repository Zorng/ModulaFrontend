import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';

final mockAttendanceRepositoryProvider = Provider<MockAttendanceRepository>((
  ref,
) {
  return MockAttendanceRepository();
});

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository({DateTime Function()? nowFactory})
    : _nowFactory = nowFactory ?? DateTime.now;

  final DateTime Function() _nowFactory;
  final List<AttendanceRecord> _records = <AttendanceRecord>[];

  static const String _tenantId = 'mock-tenant-001';
  static const String _defaultBranchId = 'mock-branch-001';
  static const String _employeeId = 'mock-staff-001';
  static const AttendanceLocationVerificationMode _locationMode =
      AttendanceLocationVerificationMode.checkinAndCheckout;
  static const AttendanceGeofence _geofence = AttendanceGeofence(
    centerLat: 11.6458916,
    centerLng: 104.8968759,
    radiusM: 120,
    // (11.5729610, 104.9085106)
  );

  int _idCounter = 1;

  final List<AttendanceShiftScheduleEntry> _schedule =
      const <AttendanceShiftScheduleEntry>[
        AttendanceShiftScheduleEntry(
          dayOfWeek: 1,
          startTime: '08:00',
          endTime: '17:00',
          isOff: false,
        ),
        AttendanceShiftScheduleEntry(
          dayOfWeek: 2,
          startTime: '08:00',
          endTime: '17:00',
          isOff: false,
        ),
        AttendanceShiftScheduleEntry(
          dayOfWeek: 3,
          startTime: '08:00',
          endTime: '17:00',
          isOff: false,
        ),
        AttendanceShiftScheduleEntry(
          dayOfWeek: 4,
          startTime: '08:00',
          endTime: '17:00',
          isOff: false,
        ),
        AttendanceShiftScheduleEntry(
          dayOfWeek: 6,
          startTime: '08:00',
          endTime: '17:00',
          isOff: false,
        ),
        AttendanceShiftScheduleEntry(dayOfWeek: 0, isOff: true),
        AttendanceShiftScheduleEntry(dayOfWeek: 6, isOff: true),
      ];

  @override
  Future<AttendanceContext> getAttendanceContext({
    required String branchId,
  }) async {
    final resolvedBranchId = _resolveBranchId(branchId);
    final now = _nowFactory().toLocal();
    final activeSession = _findActiveSession(resolvedBranchId);
    final activeShift = _resolveActiveShift(now);

    if (activeSession != null) {
      return AttendanceContext(
        canCheckIn: false,
        reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
        reasonMessage: 'You are already checked in.',
        activeShift: activeShift,
        activeAttendance: ActiveAttendanceSession(
          attendanceId: activeSession.id,
          startAt: activeSession.occurredAt.toUtc().toIso8601String(),
        ),
        locationVerificationMode: _locationMode,
        geofence: _geofence,
      );
    }

    return AttendanceContext(
      canCheckIn: true,
      reasonCode: null,
      reasonMessage: null,
      activeShift: activeShift,
      activeAttendance: null,
      locationVerificationMode: _locationMode,
      geofence: _geofence,
    );
  }

  @override
  Future<AttendanceMutationResult> checkIn(
    AttendanceCheckInPayload payload,
  ) async {
    final branchId = _resolveBranchId(payload.branchId);
    final context = await getAttendanceContext(branchId: branchId);
    if (!context.canCheckIn) {
      throw AttendanceRepositoryException(
        reasonCode: context.reasonCode ?? AttendanceReasonCodes.invalidRequest,
        message: context.reasonMessage ?? 'You cannot check in at the moment.',
      );
    }

    final occurredAt = _parseClientTs(payload.clientTs);
    final locationEval = _evaluateLocation(
      mode: _locationMode,
      deviceLat: payload.deviceLat,
      deviceLng: payload.deviceLng,
    );

    final record = AttendanceRecord(
      id: _nextId('checkin'),
      tenantId: _tenantId,
      branchId: branchId,
      employeeId: _employeeId,
      type: 'CHECK_IN',
      occurredAt: occurredAt,
      createdAt: occurredAt,
      location: _toLocation(payload.deviceLat, payload.deviceLng),
    );
    _records.add(record);

    return AttendanceMutationResult(
      attendanceId: record.id,
      status: 'CHECKED_IN',
      locationResult: locationEval.result,
      distanceM: locationEval.distanceM,
      allowedRadiusM: locationEval.allowedRadiusM,
      message: _locationMessage(locationEval.result),
      reasonCode: null,
      record: record,
    );
  }

  @override
  Future<AttendanceMutationResult> checkOut(
    AttendanceCheckOutPayload payload,
  ) async {
    final branchId = _resolveBranchId(payload.branchId);
    final activeSession = _findActiveSession(branchId);
    if (activeSession == null) {
      throw const AttendanceRepositoryException(
        reasonCode: AttendanceReasonCodes.noActiveAttendance,
        message: 'No active attendance session found to check out.',
      );
    }

    final occurredAt = _parseClientTs(payload.clientTs);
    final locationEval = _evaluateLocation(
      mode: _locationMode,
      deviceLat: payload.deviceLat,
      deviceLng: payload.deviceLng,
    );

    final record = AttendanceRecord(
      id: _nextId('checkout'),
      tenantId: activeSession.tenantId,
      branchId: activeSession.branchId,
      employeeId: activeSession.employeeId,
      type: 'CHECK_OUT',
      occurredAt: occurredAt,
      createdAt: occurredAt,
      location: _toLocation(payload.deviceLat, payload.deviceLng),
    );
    _records.add(record);

    return AttendanceMutationResult(
      attendanceId: activeSession.id,
      status: 'CHECKED_OUT',
      locationResult: locationEval.result,
      distanceM: locationEval.distanceM,
      allowedRadiusM: locationEval.allowedRadiusM,
      message: _locationMessage(locationEval.result),
      reasonCode: null,
      record: record,
    );
  }

  @override
  Future<List<AttendanceShiftScheduleEntry>> getMySchedule(
    AttendanceScheduleRange range,
  ) async {
    return List<AttendanceShiftScheduleEntry>.from(_schedule);
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords(
    AttendanceRecordsFilter filters,
  ) async {
    final filtered = _records.where((record) {
      if (filters.branchId != null &&
          filters.branchId!.isNotEmpty &&
          record.branchId != filters.branchId) {
        return false;
      }

      if (filters.selfOnly) {
        if (record.employeeId != _employeeId) return false;
      } else if (filters.employeeId != null &&
          filters.employeeId!.isNotEmpty &&
          record.employeeId != filters.employeeId) {
        return false;
      }

      if (filters.from != null && record.occurredAt.isBefore(filters.from!)) {
        return false;
      }

      if (filters.to != null && !record.occurredAt.isBefore(filters.to!)) {
        return false;
      }

      return true;
    }).toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    if (filters.offset >= filtered.length) return const [];
    final end = math.min(filtered.length, filters.offset + filters.limit);
    return filtered.sublist(filters.offset, end);
  }

  AttendanceRecord? _findActiveSession(String branchId) {
    final branchRecords =
        _records.where((record) => record.branchId == branchId).toList()
          ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    AttendanceRecord? activeCheckIn;
    for (final record in branchRecords) {
      if (record.type == 'CHECK_IN') activeCheckIn = record;
      if (record.type == 'CHECK_OUT') activeCheckIn = null;
    }
    return activeCheckIn;
  }

  AttendanceShiftWindow? _resolveActiveShift(DateTime nowLocal) {
    final targetWeekday = nowLocal.weekday % 7;
    final entry = _schedule.firstWhere(
      (item) => item.dayOfWeek == targetWeekday,
      orElse: () =>
          const AttendanceShiftScheduleEntry(dayOfWeek: -1, isOff: true),
    );
    if (entry.dayOfWeek < 0 || entry.isOff) return null;

    final startMinutes = _parseHm(entry.startTime);
    final endMinutes = _parseHm(entry.endTime);
    if (startMinutes == null || endMinutes == null) return null;

    final nowMinutes = (nowLocal.hour * 60) + nowLocal.minute;
    if (nowMinutes < startMinutes || nowMinutes > endMinutes) {
      return null;
    }

    final start = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      startMinutes ~/ 60,
      startMinutes % 60,
    );
    final end = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      endMinutes ~/ 60,
      endMinutes % 60,
    );

    return AttendanceShiftWindow(
      shiftId: 'shift-$targetWeekday',
      startAt: start.toUtc().toIso8601String(),
      endAt: end.toUtc().toIso8601String(),
    );
  }

  int? _parseHm(String? raw) {
    if (raw == null || raw.isEmpty || !raw.contains(':')) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
  }

  String _resolveBranchId(String? branchId) {
    if (branchId == null || branchId.isEmpty) return _defaultBranchId;
    return branchId;
  }

  DateTime _parseClientTs(String clientTs) {
    return DateTime.tryParse(clientTs)?.toLocal() ?? _nowFactory().toLocal();
  }

  AttendanceLocation? _toLocation(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    return AttendanceLocation(lat: lat, lng: lng);
  }

  ({AttendanceLocationResult result, double? distanceM, double? allowedRadiusM})
  _evaluateLocation({
    required AttendanceLocationVerificationMode mode,
    required double? deviceLat,
    required double? deviceLng,
  }) {
    if (mode == AttendanceLocationVerificationMode.disabled) {
      return (
        result: AttendanceLocationResult.unknown,
        distanceM: null,
        allowedRadiusM: null,
      );
    }

    if (deviceLat == null || deviceLng == null) {
      return (
        result: AttendanceLocationResult.unknown,
        distanceM: null,
        allowedRadiusM: _geofence.radiusM,
      );
    }

    final distance = _distanceMeters(
      lat1: deviceLat,
      lon1: deviceLng,
      lat2: _geofence.centerLat,
      lon2: _geofence.centerLng,
    );
    final within = distance <= _geofence.radiusM;
    return (
      result: within
          ? AttendanceLocationResult.match
          : AttendanceLocationResult.mismatch,
      distanceM: distance,
      allowedRadiusM: _geofence.radiusM,
    );
  }

  double _distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  String _locationMessage(AttendanceLocationResult result) {
    switch (result) {
      case AttendanceLocationResult.match:
        return 'Attendance recorded.';
      case AttendanceLocationResult.mismatch:
        return 'Location mismatch. This is recorded for review.';
      case AttendanceLocationResult.unknown:
        return 'Location not verified. Your attendance is still recorded.';
    }
  }

  String _nextId(String prefix) {
    final next = _idCounter;
    _idCounter += 1;
    return 'mock-$prefix-${next.toString().padLeft(4, '0')}';
  }
}
