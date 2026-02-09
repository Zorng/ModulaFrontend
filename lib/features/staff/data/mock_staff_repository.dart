import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

/// Mock repository for staff management CRUD operations
/// Provides testable staff management without backend support
/// Data resets on app refresh
class MockStaffRepository {
  MockStaffRepository() {
    _initializeMockData();
  }

  final List<Staff> _mockStaff = [];
  int _nextId = 1000;

  void _initializeMockData() {
    _mockStaff.clear();
    _mockStaff.addAll([
      Staff(
        id: '1',
        userName: 'John Manager',
        gender: 'Male',
        phoneNumber: '+85512345678',
        email: 'john.manager@example.com',
        role: 'Manager',
        branch: 'Main Branch',
        branchId: 'branch-1',
        status: 'Active',
        isActive: true,
        scheduleOption: 'same_hours',
        workingDays: {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'},
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
      ),
      Staff(
        id: '2',
        userName: 'Sarah Cashier',
        gender: 'Female',
        phoneNumber: '+85512345679',
        email: 'sarah.cashier@example.com',
        role: 'Cashier',
        branch: 'Main Branch',
        branchId: 'branch-1',
        status: 'Active',
        isActive: true,
        scheduleOption: 'same_hours',
        workingDays: {'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'},
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
      ),
      Staff(
        id: '3',
        userName: 'Mike Admin',
        gender: 'Male',
        phoneNumber: '+85512345680',
        email: 'mike.admin@example.com',
        role: 'Admin',
        branch: 'Downtown Branch',
        branchId: 'branch-2',
        status: 'Active',
        isActive: true,
        scheduleOption: 'same_hours',
        workingDays: {
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        },
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
      ),
      Staff(
        id: '4',
        userName: 'Emma Cashier',
        gender: 'Female',
        phoneNumber: '+85512345681',
        email: 'emma.invited@example.com',
        role: 'Cashier',
        branch: 'Main Branch',
        branchId: 'branch-1',
        status: 'Invited',
        isActive: false,
        scheduleOption: 'same_hours',
        workingDays: {'Monday', 'Wednesday', 'Friday'},
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
      ),
    ]);
    _nextId = 1000;
  }

  Future<List<Staff>> fetchStaff({String? branchId}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (branchId == null || branchId.isEmpty) {
      return List.from(_mockStaff);
    }

    return _mockStaff.where((s) => s.branchId == branchId).toList();
  }

  Future<List<ShiftScheduleEntry>> fetchShiftSchedule({
    required String userId,
    required String branchId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final staff = _mockStaff.firstWhere(
      (s) => s.id == userId,
      orElse: () =>
          Staff(userName: '', phoneNumber: '', email: '', isActive: false),
    );

    if (staff.shiftSchedule != null) {
      return staff.shiftSchedule!;
    }

    // Generate default schedule from staff working days
    if (staff.workingDays != null &&
        staff.startTime != null &&
        staff.endTime != null) {
      final days = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ];
      return List.generate(7, (index) {
        final day = days[index];
        final isWorkingDay = staff.workingDays!.contains(day);
        return ShiftScheduleEntry(
          dayOfWeek: index, // 0=Sunday, 1=Monday, etc.
          startTime: isWorkingDay ? _formatTime(staff.startTime!) : null,
          endTime: isWorkingDay ? _formatTime(staff.endTime!) : null,
          isOff: !isWorkingDay,
        );
      });
    }

    return [];
  }

  Future<Staff> createInvite(Staff staff) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newStaff = staff.copyWith(
      id: 'mock-${_nextId++}',
      status: 'Invited',
      isActive: false,
    );

    _mockStaff.add(newStaff);
    return newStaff;
  }

  Future<Staff> updateStaff(Staff staff) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _mockStaff.indexWhere((s) => s.id == staff.id);
    if (index == -1) {
      throw Exception('Staff member not found');
    }

    _mockStaff[index] = staff;
    return staff;
  }

  Future<Staff> updateStaffStatus(String staffId, String status) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockStaff.indexWhere((s) => s.id == staffId);
    if (index == -1) {
      throw Exception('Staff member not found');
    }

    final updatedStaff = _mockStaff[index].copyWith(
      status: status,
      isActive: status.toLowerCase() == 'active',
    );

    _mockStaff[index] = updatedStaff;
    return updatedStaff;
  }

  Future<void> deleteStaff(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockStaff.removeWhere((s) => s.id == staffId);
  }

  void reset() {
    _initializeMockData();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
