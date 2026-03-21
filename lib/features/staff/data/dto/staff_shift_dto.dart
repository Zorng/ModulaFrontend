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

class StaffOffsetPageDto<T> {
  const StaffOffsetPageDto({
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

  factory StaffOffsetPageDto.fromJson(
    dynamic raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (raw is List) {
      final legacyItems = raw
          .whereType<Map>()
          .map((entry) => fromJson(Map<String, dynamic>.from(entry)))
          .toList(growable: false);
      return StaffOffsetPageDto<T>(
        items: legacyItems,
        limit: legacyItems.length,
        offset: 0,
        total: legacyItems.length,
        hasMore: false,
      );
    }

    final json = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final rawItems =
        json['items'] ?? json['data'] ?? json['rows'] ?? json['results'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((entry) => fromJson(Map<String, dynamic>.from(entry)))
              .toList(growable: false)
        : List<T>.empty(growable: false);

    final limit =
        StaffApiHelpers.parseInt(json['limit']) ??
        StaffApiHelpers.parseInt(json['pageSize']) ??
        StaffApiHelpers.parseInt(json['perPage']) ??
        items.length;
    final offset =
        StaffApiHelpers.parseInt(json['offset']) ??
        StaffApiHelpers.parseInt(json['skip']) ??
        0;
    final total =
        StaffApiHelpers.parseInt(json['total']) ??
        StaffApiHelpers.parseInt(json['totalCount']) ??
        StaffApiHelpers.parseInt(json['count']) ??
        items.length;
    final hasMoreValue =
        json['hasMore'] ?? json['has_more'] ?? json['nextPage'] != null;
    final hasMore = hasMoreValue is bool
        ? hasMoreValue
        : (offset + items.length) < total;

    return StaffOffsetPageDto<T>(
      items: items,
      limit: limit,
      offset: offset,
      total: total,
      hasMore: hasMore,
    );
  }
}

class StaffShiftScheduleDto {
  const StaffShiftScheduleDto({
    required this.patternPage,
    required this.instancePage,
    required this.membershipId,
  });

  final StaffOffsetPageDto<StaffShiftPatternDto> patternPage;
  final StaffOffsetPageDto<StaffShiftInstanceDto> instancePage;
  final String? membershipId;

  List<StaffShiftPatternDto> get patterns => patternPage.items;
  List<StaffShiftInstanceDto> get instances => instancePage.items;

  factory StaffShiftScheduleDto.fromJson(Map<String, dynamic> json) {
    final scheduleJson = json['schedule'] is Map
        ? Map<String, dynamic>.from(json['schedule'] as Map)
        : json;

    return StaffShiftScheduleDto(
      patternPage: StaffOffsetPageDto<StaffShiftPatternDto>.fromJson(
        scheduleJson['patterns'] ?? scheduleJson['patternPage'],
        StaffShiftPatternDto.fromJson,
      ),
      instancePage: StaffOffsetPageDto<StaffShiftInstanceDto>.fromJson(
        scheduleJson['instances'] ?? scheduleJson['instancePage'],
        StaffShiftInstanceDto.fromJson,
      ),
      membershipId: scheduleJson['membershipId']?.toString(),
    );
  }
}
