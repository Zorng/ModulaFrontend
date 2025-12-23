import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/staff_management_api.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

final staffManagementRepositoryProvider =
    Provider<StaffManagementRepository>((ref) {
      final api = ref.watch(staffManagementApiProvider);
      return StaffManagementRepository(api);
    });

class StaffManagementRepository {
  StaffManagementRepository(this._api);

  final StaffManagementApi _api;

  Future<List<Staff>> fetchStaff({String? branchId}) async {
    final payload = await _api.fetchStaffList(branchId: branchId);
    final raw = payload['staff'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => _mapStaff(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ShiftScheduleEntry>> fetchShiftSchedule({
    required String userId,
    required String branchId,
  }) async {
    final payload =
        await _api.fetchShiftSchedule(userId: userId, branchId: branchId);
    final raw = payload['schedule'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => _mapScheduleEntry(Map<String, dynamic>.from(item)))
        .toList();
  }

  Staff _mapStaff(Map<String, dynamic> json) {
    final first = json['first_name']?.toString() ?? '';
    final last = json['last_name']?.toString() ?? '';
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    final recordType = json['record_type']?.toString().toUpperCase() ?? '';
    final statusRaw = json['status']?.toString().toUpperCase() ?? '';
    final status =
        statusRaw.isNotEmpty ? statusRaw : (recordType == 'INVITE' ? 'INVITED' : '');
    final roleRaw = json['role']?.toString() ?? '';
    final branchName = json['branch_name']?.toString() ?? '';
    final phone = json['phone']?.toString() ?? '';

    return Staff(
      id: json['id']?.toString() ?? '',
      userName: fullName.isNotEmpty ? fullName : phone,
      gender: null,
      phoneNumber: phone,
      email: json['email']?.toString() ?? '',
      role: _titleCase(roleRaw),
      branch: branchName.isNotEmpty ? branchName : null,
      branchId: json['branch_id']?.toString(),
      status: status.isNotEmpty ? _titleCase(status) : null,
      isActive: status == 'ACTIVE',
      scheduleOption: null,
      workingDays: null,
      startTime: null,
      endTime: null,
      customHours: null,
      shiftSchedule: null,
    );
  }

  ShiftScheduleEntry _mapScheduleEntry(Map<String, dynamic> json) {
    return ShiftScheduleEntry(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? -1,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      isOff: json['is_off'] as bool? ?? false,
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
