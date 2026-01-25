import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/staff_management_api.dart';
import 'package:modular_pos/features/staff/data/dto/shift_schedule_entry_dto.dart';
import 'package:modular_pos/features/staff/data/dto/staff_dto.dart';
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
    final staff = await _api.fetchStaffList(branchId: branchId);
    return staff.map(_mapStaff).toList();
  }

  Future<List<ShiftScheduleEntry>> fetchShiftSchedule({
    required String userId,
    required String branchId,
  }) async {
    final schedule =
        await _api.fetchShiftSchedule(userId: userId, branchId: branchId);
    return schedule.map(_mapScheduleEntry).toList();
  }

  Staff _mapStaff(StaffDto dto) {
    final first = dto.firstName;
    final last = dto.lastName;
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    final recordType = dto.recordType.toUpperCase();
    final statusRaw = dto.status.toUpperCase();
    final status =
        statusRaw.isNotEmpty ? statusRaw : (recordType == 'INVITE' ? 'INVITED' : '');
    final roleRaw = dto.role;
    final branchName = dto.branchName;
    final phone = dto.phone;

    return Staff(
      id: dto.id,
      userName: fullName.isNotEmpty ? fullName : phone,
      gender: null,
      phoneNumber: phone,
      email: dto.email,
      role: _titleCase(roleRaw),
      branch: branchName.isNotEmpty ? branchName : null,
      branchId: dto.branchId,
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

  ShiftScheduleEntry _mapScheduleEntry(ShiftScheduleEntryDto dto) {
    return ShiftScheduleEntry(
      dayOfWeek: dto.dayOfWeek,
      startTime: dto.startTime,
      endTime: dto.endTime,
      isOff: dto.isOff,
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
