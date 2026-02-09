import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/staff_management_api.dart';
import 'package:modular_pos/features/staff/data/dto/shift_schedule_entry_dto.dart';
import 'package:modular_pos/features/staff/data/dto/staff_dto.dart';
import 'package:modular_pos/features/staff/data/dto/create_staff_request_dto.dart';
import 'package:modular_pos/features/staff/data/mock_staff_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

/// Provider to control whether to use mock or real repository
/// Set to true for testing CRUD operations without backend
final useMockStaffRepositoryProvider = NotifierProvider<_UseMockNotifier, bool>(
  _UseMockNotifier.new,
);

class _UseMockNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Default to real API

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final staffManagementRepositoryProvider = Provider<StaffManagementRepository>((
  ref,
) {
  final useMock = ref.watch(useMockStaffRepositoryProvider);
  if (useMock) {
    return StaffManagementRepository.mock();
  }
  final api = ref.watch(staffManagementApiProvider);
  return StaffManagementRepository(api);
});

class StaffManagementRepository {
  StaffManagementRepository(this._api) : _mockRepo = null, _isMock = false;

  StaffManagementRepository.mock()
    : _api = null,
      _mockRepo = MockStaffRepository(),
      _isMock = true;

  final StaffManagementApi? _api;
  final MockStaffRepository? _mockRepo;
  final bool _isMock;

  Future<List<Staff>> fetchStaff({String? branchId}) async {
    if (_isMock) {
      return await _mockRepo!.fetchStaff(branchId: branchId);
    }
    final staff = await _api!.fetchStaffList(branchId: branchId);
    return staff.map(_mapStaff).toList();
  }

  Future<List<ShiftScheduleEntry>> fetchShiftSchedule({
    required String userId,
    required String branchId,
  }) async {
    if (_isMock) {
      return await _mockRepo!.fetchShiftSchedule(
        userId: userId,
        branchId: branchId,
      );
    }
    final schedule = await _api!.fetchShiftSchedule(
      userId: userId,
      branchId: branchId,
    );
    return schedule.map(_mapScheduleEntry).toList();
  }

  Future<Staff> createInvite(Staff staff) async {
    if (_isMock) {
      return await _mockRepo!.createInvite(staff);
    }
    final names = staff.userName.split(' ');
    final firstName = names.isNotEmpty ? names.first : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    final phone = staff.phoneNumber.startsWith('+')
        ? staff.phoneNumber
        : staff.phoneNumber.startsWith('0')
        ? '+855${staff.phoneNumber.substring(1)}'
        : '+855${staff.phoneNumber}';
    final request = InviteStaffRequestDto(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      role: (staff.role ?? 'CASHIER').toUpperCase(),
      branchId: staff.branchId ?? '',
      note: 'Created via admin portal',
    );
    final dto = await _api!.createInvite(request);
    return _mapStaff(dto);
  }

  /// Update staff details (mock only until backend supports it)
  Future<Staff> updateStaff(Staff staff) async {
    if (_isMock) {
      return await _mockRepo!.updateStaff(staff);
    }
    // TODO: Implement when backend API is available
    throw UnimplementedError('Update staff is only available in mock mode');
  }

  /// Update staff status (mock only until backend supports it)
  Future<Staff> updateStaffStatus(String staffId, String status) async {
    if (_isMock) {
      return await _mockRepo!.updateStaffStatus(staffId, status);
    }
    // TODO: Implement when backend API is available
    throw UnimplementedError(
      'Update staff status is only available in mock mode',
    );
  }

  /// Delete staff (mock only until backend supports it)
  Future<void> deleteStaff(String staffId) async {
    if (_isMock) {
      return await _mockRepo!.deleteStaff(staffId);
    }
    // TODO: Implement when backend API is available
    throw UnimplementedError('Delete staff is only available in mock mode');
  }

  /// Reset mock data (mock only)
  void resetMockData() {
    if (_isMock) {
      _mockRepo!.reset();
    }
  }

  // String _formatTime(TimeOfDay? time) {
  //   if (time == null) return '';
  //   return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  // }

  Staff _mapStaff(StaffDto dto) {
    final first = dto.firstName;
    final last = dto.lastName;
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    final recordType = dto.recordType.toUpperCase();
    final statusRaw = dto.status.toUpperCase();
    final status = statusRaw.isNotEmpty
        ? statusRaw
        : (recordType == 'INVITE' ? 'INVITED' : '');
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
