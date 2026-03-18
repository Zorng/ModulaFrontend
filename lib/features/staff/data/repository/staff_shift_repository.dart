import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/api/staff_shift_api.dart';
import 'package:modular_pos/features/staff/data/dto/staff_shift_dto.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

abstract class StaffShiftRepository {
  Future<StaffShiftSchedule> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
    int? limit,
    int? offset,
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
  static const _defaultPageLimit = 200;
  static const _maxPageLimit = 500;

  @override
  Future<StaffShiftSchedule> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
    int? limit,
    int? offset,
  }) async {
    final normalizedLimit = _normalizeLimit(limit);
    final normalizedOffset = _normalizeOffset(offset);
    final cleanMembershipId = (membershipId ?? '').trim();
    final dto = cleanMembershipId.isNotEmpty
        ? await _api.fetchMembershipSchedule(
            membershipId: cleanMembershipId,
            from: from,
            to: to,
            limit: normalizedLimit,
            offset: normalizedOffset,
          )
        : await _api.fetchSchedule(
            branchId: branchId,
            from: from,
            to: to,
            limit: normalizedLimit,
            offset: normalizedOffset,
          );
    return _toSchedule(dto);
  }

  @override
  Future<StaffShiftSchedule> fetchMySchedule() async {
    final dto = await _api.fetchMySchedule();
    return _toSchedule(dto);
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
    return _toPattern(dto);
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
    return _toPattern(dto);
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
    return _toPattern(dto);
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
    return _toInstance(dto);
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
    return _toInstance(dto);
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
    return _toInstance(dto);
  }

  StaffShiftSchedule _toSchedule(StaffShiftScheduleDto dto) {
    return StaffShiftSchedule(
      patternPage: OffsetPage<StaffShiftPattern>(
        items: dto.patternPage.items
            .map<StaffShiftPattern>(_toPattern)
            .toList(growable: false),
        limit: dto.patternPage.limit,
        offset: dto.patternPage.offset,
        total: dto.patternPage.total,
        hasMore: dto.patternPage.hasMore,
      ),
      instancePage: OffsetPage<StaffShiftInstance>(
        items: dto.instancePage.items
            .map<StaffShiftInstance>(_toInstance)
            .toList(growable: false),
        limit: dto.instancePage.limit,
        offset: dto.instancePage.offset,
        total: dto.instancePage.total,
        hasMore: dto.instancePage.hasMore,
      ),
      membershipId: dto.membershipId,
    );
  }

  int _normalizeLimit(int? value) {
    if (value == null || value <= 0) return _defaultPageLimit;
    if (value > _maxPageLimit) return _maxPageLimit;
    return value;
  }

  int _normalizeOffset(int? value) {
    if (value == null || value < 0) return 0;
    return value;
  }

  StaffShiftPattern _toPattern(dynamic dto) {
    return StaffShiftPattern(
      id: dto.id,
      tenantId: dto.tenantId,
      membershipId: dto.membershipId,
      branchId: dto.branchId,
      daysOfWeek: dto.daysOfWeek,
      plannedStartTime: dto.plannedStartTime,
      plannedEndTime: dto.plannedEndTime,
      status: parseStaffShiftPatternStatus(dto.status),
      effectiveFrom: dto.effectiveFrom,
      effectiveTo: dto.effectiveTo,
      note: dto.note,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  StaffShiftInstance _toInstance(dynamic dto) {
    return StaffShiftInstance(
      id: dto.id,
      tenantId: dto.tenantId,
      membershipId: dto.membershipId,
      branchId: dto.branchId,
      patternId: dto.patternId,
      date: dto.date,
      plannedStartTime: dto.plannedStartTime,
      plannedEndTime: dto.plannedEndTime,
      status: parseStaffShiftInstanceStatus(dto.status),
      note: dto.note,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
