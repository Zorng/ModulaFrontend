import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';

class StaffShiftPatternDto {
  const StaffShiftPatternDto({
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
  final String status;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StaffShiftPatternDto.fromJson(Map<String, dynamic> json) {
    final rawDays = json['daysOfWeek'];
    final days = rawDays is List
        ? rawDays
              .map((entry) => StaffApiHelpers.parseInt(entry))
              .whereType<int>()
              .toList(growable: false)
        : const <int>[];
    return StaffShiftPatternDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      membershipId: json['membershipId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      daysOfWeek: days,
      plannedStartTime: json['plannedStartTime']?.toString() ?? '',
      plannedEndTime: json['plannedEndTime']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      effectiveFrom: StaffApiHelpers.parseDateTime(json['effectiveFrom']),
      effectiveTo: StaffApiHelpers.parseDateTime(json['effectiveTo']),
      note: json['note']?.toString(),
      createdAt:
          StaffApiHelpers.parseDateTime(json['createdAt']) ?? DateTime(1970),
      updatedAt:
          StaffApiHelpers.parseDateTime(json['updatedAt']) ?? DateTime(1970),
    );
  }
}

class StaffShiftInstanceDto {
  const StaffShiftInstanceDto({
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
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StaffShiftInstanceDto.fromJson(Map<String, dynamic> json) {
    return StaffShiftInstanceDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      membershipId: json['membershipId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      patternId: json['patternId']?.toString(),
      date: StaffApiHelpers.parseDateTime(json['date']) ?? DateTime(1970),
      plannedStartTime: json['plannedStartTime']?.toString() ?? '',
      plannedEndTime: json['plannedEndTime']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt:
          StaffApiHelpers.parseDateTime(json['createdAt']) ?? DateTime(1970),
      updatedAt:
          StaffApiHelpers.parseDateTime(json['updatedAt']) ?? DateTime(1970),
    );
  }
}

class StaffShiftScheduleDto {
  const StaffShiftScheduleDto({
    required this.patterns,
    required this.instances,
    required this.membershipId,
  });

  final List<StaffShiftPatternDto> patterns;
  final List<StaffShiftInstanceDto> instances;
  final String? membershipId;

  factory StaffShiftScheduleDto.fromJson(Map<String, dynamic> json) {
    final rawPatterns = json['patterns'];
    final rawInstances = json['instances'];
    return StaffShiftScheduleDto(
      patterns: rawPatterns is List
          ? rawPatterns
                .whereType<Map>()
                .map(
                  (entry) =>
                      StaffShiftPatternDto.fromJson(Map<String, dynamic>.from(entry)),
                )
                .toList(growable: false)
          : const <StaffShiftPatternDto>[],
      instances: rawInstances is List
          ? rawInstances
                .whereType<Map>()
                .map(
                  (entry) => StaffShiftInstanceDto.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const <StaffShiftInstanceDto>[],
      membershipId: json['membershipId']?.toString(),
    );
  }
}
