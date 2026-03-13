enum StaffShiftPatternStatus { active, inactive, unknown }

StaffShiftPatternStatus parseStaffShiftPatternStatus(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ACTIVE':
      return StaffShiftPatternStatus.active;
    case 'INACTIVE':
      return StaffShiftPatternStatus.inactive;
    default:
      return StaffShiftPatternStatus.unknown;
  }
}

enum StaffShiftInstanceStatus { planned, updated, cancelled, unknown }

StaffShiftInstanceStatus parseStaffShiftInstanceStatus(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'PLANNED':
      return StaffShiftInstanceStatus.planned;
    case 'UPDATED':
      return StaffShiftInstanceStatus.updated;
    case 'CANCELLED':
      return StaffShiftInstanceStatus.cancelled;
    default:
      return StaffShiftInstanceStatus.unknown;
  }
}

class StaffShiftPattern {
  const StaffShiftPattern({
    required this.id,
    required this.tenantId,
    required this.membershipId,
    required this.branchId,
    required this.daysOfWeek,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.status,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String membershipId;
  final String branchId;
  final List<int> daysOfWeek;
  final String plannedStartTime;
  final String plannedEndTime;
  final StaffShiftPatternStatus status;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class StaffShiftInstance {
  const StaffShiftInstance({
    required this.id,
    required this.tenantId,
    required this.membershipId,
    required this.branchId,
    required this.patternId,
    required this.date,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String membershipId;
  final String branchId;
  final String? patternId;
  final DateTime date;
  final String plannedStartTime;
  final String plannedEndTime;
  final StaffShiftInstanceStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class StaffShiftSchedule {
  const StaffShiftSchedule({
    required this.patterns,
    required this.instances,
    this.membershipId,
  });

  final List<StaffShiftPattern> patterns;
  final List<StaffShiftInstance> instances;
  final String? membershipId;
}
