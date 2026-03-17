import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/api/staff_shift_api.dart';
import 'package:modular_pos/features/staff/data/staff_shift_mapper.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

abstract class StaffShiftRepository {
  Future<StaffShiftSchedule> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
  });

  Future<StaffShiftSchedule> fetchMySchedule();

  Future<StaffShiftPattern> createPattern({
    required String membershipId,
    required String branchId,
    required List<int> daysOfWeek,
    required String plannedStartTime,
    required String plannedEndTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  });

  Future<StaffShiftPattern> updatePattern({
    required String patternId,
    List<int>? daysOfWeek,
    String? plannedStartTime,
    String? plannedEndTime,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  });

  Future<StaffShiftPattern> deactivatePattern({
    required String patternId,
    required String reason,
    String? intentId,
  });

  Future<StaffShiftInstance> createInstance({
    required String membershipId,
    required String branchId,
    required DateTime date,
    required String plannedStartTime,
    required String plannedEndTime,
    String? note,
    String? intentId,
  });

  Future<StaffShiftInstance> updateInstance({
    required String instanceId,
    DateTime? date,
    String? plannedStartTime,
    String? plannedEndTime,
    String? note,
    String? intentId,
  });

  Future<StaffShiftInstance> cancelInstance({
    required String instanceId,
    required String reason,
    String? intentId,
  });
}

final staffShiftRepositoryProvider = Provider<StaffShiftRepository>((ref) {
  final api = ref.read(staffShiftApiProvider);
  return RemoteStaffShiftRepository(api);
});

class RemoteStaffShiftRepository implements StaffShiftRepository {
  const RemoteStaffShiftRepository(this._api);

  final StaffShiftApi _api;

  @override
  Future<StaffShiftSchedule> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
  }) async {
    final dto = await _api.fetchSchedule(
      branchId: branchId,
      from: from,
      to: to,
      membershipId: membershipId,
    );
    return mapStaffShiftScheduleDto(dto);
  }

  @override
  Future<StaffShiftSchedule> fetchMySchedule() async {
    final dto = await _api.fetchMySchedule();
    return mapStaffShiftScheduleDto(dto);
  }

  @override
  Future<StaffShiftPattern> createPattern({
    required String membershipId,
    required String branchId,
    required List<int> daysOfWeek,
    required String plannedStartTime,
    required String plannedEndTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  }) async {
    final dto = await _api.createPattern(
      payload: {
        'membershipId': membershipId.trim(),
        'branchId': branchId.trim(),
        'daysOfWeek': daysOfWeek,
        'plannedStartTime': plannedStartTime.trim(),
        'plannedEndTime': plannedEndTime.trim(),
        'effectiveFrom': effectiveFrom?.toIso8601String().split('T').first,
        'effectiveTo': effectiveTo?.toIso8601String().split('T').first,
        'note': note,
      }..removeWhere((key, value) => value == null),
      intentId: intentId,
    );
    return mapStaffShiftPatternDto(dto);
  }

  @override
  Future<StaffShiftPattern> updatePattern({
    required String patternId,
    List<int>? daysOfWeek,
    String? plannedStartTime,
    String? plannedEndTime,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  }) async {
    final dto = await _api.updatePattern(
      patternId: patternId,
      payload: {
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if ((plannedStartTime ?? '').trim().isNotEmpty)
          'plannedStartTime': plannedStartTime!.trim(),
        if ((plannedEndTime ?? '').trim().isNotEmpty)
          'plannedEndTime': plannedEndTime!.trim(),
        if (effectiveTo != null)
          'effectiveTo': effectiveTo.toIso8601String().split('T').first,
        if (note != null) 'note': note,
      },
      intentId: intentId,
    );
    return mapStaffShiftPatternDto(dto);
  }

  @override
  Future<StaffShiftPattern> deactivatePattern({
    required String patternId,
    required String reason,
    String? intentId,
  }) async {
    final dto = await _api.deactivatePattern(
      patternId: patternId,
      reason: reason,
      intentId: intentId,
    );
    return mapStaffShiftPatternDto(dto);
  }

  @override
  Future<StaffShiftInstance> createInstance({
    required String membershipId,
    required String branchId,
    required DateTime date,
    required String plannedStartTime,
    required String plannedEndTime,
    String? note,
    String? intentId,
  }) async {
    final dto = await _api.createInstance(
      payload: {
        'membershipId': membershipId.trim(),
        'branchId': branchId.trim(),
        'date': date.toIso8601String().split('T').first,
        'plannedStartTime': plannedStartTime.trim(),
        'plannedEndTime': plannedEndTime.trim(),
        'note': note,
      }..removeWhere((key, value) => value == null),
      intentId: intentId,
    );
    return mapStaffShiftInstanceDto(dto);
  }

  @override
  Future<StaffShiftInstance> updateInstance({
    required String instanceId,
    DateTime? date,
    String? plannedStartTime,
    String? plannedEndTime,
    String? note,
    String? intentId,
  }) async {
    final dto = await _api.updateInstance(
      instanceId: instanceId,
      payload: {
        if (date != null) 'date': date.toIso8601String().split('T').first,
        if ((plannedStartTime ?? '').trim().isNotEmpty)
          'plannedStartTime': plannedStartTime!.trim(),
        if ((plannedEndTime ?? '').trim().isNotEmpty)
          'plannedEndTime': plannedEndTime!.trim(),
        if (note != null) 'note': note,
      },
      intentId: intentId,
    );
    return mapStaffShiftInstanceDto(dto);
  }

  @override
  Future<StaffShiftInstance> cancelInstance({
    required String instanceId,
    required String reason,
    String? intentId,
  }) async {
    final dto = await _api.cancelInstance(
      instanceId: instanceId,
      reason: reason,
      intentId: intentId,
    );
    return mapStaffShiftInstanceDto(dto);
  }
}
