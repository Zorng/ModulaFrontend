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

class OffsetPage<T> {
  const OffsetPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  static OffsetPage<T> empty<T>({int limit = 50}) {
    return OffsetPage<T>(
      items: List<T>.empty(growable: false),
      limit: limit,
      offset: 0,
      total: 0,
      hasMore: false,
    );
  }
}

class StaffShiftSchedule {
  StaffShiftSchedule({
    List<StaffShiftPattern>? patterns,
    List<StaffShiftInstance>? instances,
    OffsetPage<StaffShiftPattern>? patternPage,
    OffsetPage<StaffShiftInstance>? instancePage,
    this.membershipId,
  }) : patternPage =
           patternPage ??
           OffsetPage<StaffShiftPattern>(
             items: patterns ?? const <StaffShiftPattern>[],
             limit: 200,
             offset: 0,
             total: 0,
             hasMore: false,
           ),
       instancePage =
           instancePage ??
           OffsetPage<StaffShiftInstance>(
             items: instances ?? const <StaffShiftInstance>[],
             limit: 200,
             offset: 0,
             total: 0,
             hasMore: false,
           );

  final OffsetPage<StaffShiftPattern> patternPage;
  final OffsetPage<StaffShiftInstance> instancePage;
  final String? membershipId;

  List<StaffShiftPattern> get patterns => patternPage.items;
  List<StaffShiftInstance> get instances => instancePage.items;
}
