import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/dto/staff_attendance_record_dto.dart';
import 'package:modular_pos/features/staff/data/staff_admin_attendance_api.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_record.dart';

final staffAdminAttendanceRepositoryProvider =
    Provider<StaffAdminAttendanceRepository>((ref) {
      final api = ref.watch(staffAdminAttendanceApiProvider);
      return StaffAdminAttendanceRepository(api);
    });

class StaffAdminAttendanceRepository {
  StaffAdminAttendanceRepository(this._api);

  final StaffAdminAttendanceApi _api;

  Future<List<StaffAttendanceRecord>> fetchAttendanceRecords({
    String? branchId,
    String? employeeId,
    String? from,
    String? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final records = await _api.fetchAttendanceRecords(
      branchId: branchId,
      employeeId: employeeId,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    return records.map(_mapRecord).toList();
  }

  StaffAttendanceRecord _mapRecord(StaffAttendanceRecordDto dto) {
    StaffAttendanceLocation? parsedLocation;
    final location = dto.location;
    if (location != null) {
      parsedLocation = StaffAttendanceLocation(
        lat: location.lat,
        lng: location.lng,
      );
    }
    return StaffAttendanceRecord(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      employeeId: dto.employeeId,
      type: dto.type,
      occurredAt: dto.occurredAt.toLocal(),
      createdAt: dto.createdAt.toLocal(),
      location: parsedLocation,
    );
  }
}
