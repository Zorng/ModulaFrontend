import 'package:modular_pos/features/reporting/data/dto/report_scope_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/reporting_dto_utils.dart';

class AttendanceClassificationCountsDto {
  const AttendanceClassificationCountsDto({
    required this.onTime,
    required this.late,
    required this.earlyLeave,
    required this.absent,
    required this.overtime,
    required this.unscheduledWork,
    required this.incompleteRecord,
  });

  final int onTime;
  final int late;
  final int earlyLeave;
  final int absent;
  final int overtime;
  final int unscheduledWork;
  final int incompleteRecord;

  factory AttendanceClassificationCountsDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceClassificationCountsDto(
      onTime: dtoToInt(json['onTime']),
      late: dtoToInt(json['late']),
      earlyLeave: dtoToInt(json['earlyLeave']),
      absent: dtoToInt(json['absent']),
      overtime: dtoToInt(json['overtime']),
      unscheduledWork: dtoToInt(json['unscheduledWork']),
      incompleteRecord: dtoToInt(json['incompleteRecord']),
    );
  }
}

class AttendanceBranchTotalsDto {
  const AttendanceBranchTotalsDto({
    required this.plannedShiftCount,
    required this.attendedCount,
    required this.classificationCounts,
    required this.totalScheduledHours,
    required this.totalWorkedHours,
    required this.totalLateMinutes,
    required this.totalEarlyLeaveMinutes,
    required this.totalOvertimeMinutes,
  });

  final int? plannedShiftCount;
  final int attendedCount;
  final AttendanceClassificationCountsDto classificationCounts;
  final double? totalScheduledHours;
  final double totalWorkedHours;
  final int totalLateMinutes;
  final int totalEarlyLeaveMinutes;
  final int totalOvertimeMinutes;

  factory AttendanceBranchTotalsDto.fromJson(Map<String, dynamic> json) {
    return AttendanceBranchTotalsDto(
      plannedShiftCount: json['plannedShiftCount'] == null
          ? null
          : dtoToInt(json['plannedShiftCount']),
      attendedCount: dtoToInt(json['attendedCount']),
      classificationCounts: AttendanceClassificationCountsDto.fromJson(
        asDtoMap(json['classificationCounts']),
      ),
      totalScheduledHours: dtoToNullableDouble(json['totalScheduledHours']),
      totalWorkedHours: dtoToDouble(json['totalWorkedHours']),
      totalLateMinutes: dtoToInt(json['totalLateMinutes']),
      totalEarlyLeaveMinutes: dtoToInt(json['totalEarlyLeaveMinutes']),
      totalOvertimeMinutes: dtoToInt(json['totalOvertimeMinutes']),
    );
  }
}

class AttendanceStaffSummaryDto {
  const AttendanceStaffSummaryDto({
    required this.membershipId,
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.plannedShiftCount,
    required this.attendedCount,
    required this.classificationCounts,
    required this.totalScheduledHours,
    required this.totalWorkedHours,
    required this.totalLateMinutes,
    required this.totalEarlyLeaveMinutes,
    required this.totalOvertimeMinutes,
    required this.planningCoverage,
  });

  final String membershipId;
  final String accountId;
  final String? firstName;
  final String? lastName;
  final int? plannedShiftCount;
  final int attendedCount;
  final AttendanceClassificationCountsDto classificationCounts;
  final double? totalScheduledHours;
  final double totalWorkedHours;
  final int totalLateMinutes;
  final int totalEarlyLeaveMinutes;
  final int totalOvertimeMinutes;
  final String planningCoverage;

  factory AttendanceStaffSummaryDto.fromJson(Map<String, dynamic> json) {
    return AttendanceStaffSummaryDto(
      membershipId: dtoToString(json['membershipId']),
      accountId: dtoToString(json['accountId']),
      firstName: dtoToNullableString(json['firstName']),
      lastName: dtoToNullableString(json['lastName']),
      plannedShiftCount: json['plannedShiftCount'] == null
          ? null
          : dtoToInt(json['plannedShiftCount']),
      attendedCount: dtoToInt(json['attendedCount']),
      classificationCounts: AttendanceClassificationCountsDto.fromJson(
        asDtoMap(json['classificationCounts']),
      ),
      totalScheduledHours: dtoToNullableDouble(json['totalScheduledHours']),
      totalWorkedHours: dtoToDouble(json['totalWorkedHours']),
      totalLateMinutes: dtoToInt(json['totalLateMinutes']),
      totalEarlyLeaveMinutes: dtoToInt(json['totalEarlyLeaveMinutes']),
      totalOvertimeMinutes: dtoToInt(json['totalOvertimeMinutes']),
      planningCoverage: dtoToString(json['planningCoverage']),
    );
  }
}

class AttendanceSummaryReportDto {
  const AttendanceSummaryReportDto({
    required this.scope,
    required this.planningCoverage,
    required this.branchTotals,
    required this.perStaff,
  });

  final ReportScopeDto scope;
  final String planningCoverage;
  final AttendanceBranchTotalsDto branchTotals;
  final List<AttendanceStaffSummaryDto> perStaff;

  factory AttendanceSummaryReportDto.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryReportDto(
      scope: ReportScopeDto.fromJson(asDtoMap(json['scope'])),
      planningCoverage: dtoToString(json['planningCoverage']),
      branchTotals: AttendanceBranchTotalsDto.fromJson(
        asDtoMap(json['branchTotals']),
      ),
      perStaff: asDtoList(
        json['perStaff'],
      ).map(AttendanceStaffSummaryDto.fromJson).toList(growable: false),
    );
  }
}

class AttendanceDrillDownReportDto {
  const AttendanceDrillDownReportDto({
    required this.scope,
    required this.items,
    required this.limit,
    required this.offset,
  });

  final ReportScopeDto scope;
  final List<AttendanceDrillDownItemDto> items;
  final int limit;
  final int offset;

  factory AttendanceDrillDownReportDto.fromJson(Map<String, dynamic> json) {
    return AttendanceDrillDownReportDto(
      scope: ReportScopeDto.fromJson(asDtoMap(json['scope'])),
      items: asDtoList(
        json['items'],
      ).map(AttendanceDrillDownItemDto.fromJson).toList(growable: false),
      limit: dtoToInt(json['limit']),
      offset: dtoToInt(json['offset']),
    );
  }
}

class AttendanceDrillDownItemDto {
  const AttendanceDrillDownItemDto({
    required this.workReviewId,
    required this.membershipId,
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.branchId,
    required this.workDate,
    required this.classification,
    required this.expectedStartTime,
    required this.expectedEndTime,
    required this.actualStartAt,
    required this.actualEndAt,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    required this.overtimeMinutes,
  });

  final String workReviewId;
  final String membershipId;
  final String accountId;
  final String? firstName;
  final String? lastName;
  final String branchId;
  final String workDate;
  final String classification;
  final String? expectedStartTime;
  final String? expectedEndTime;
  final DateTime? actualStartAt;
  final DateTime? actualEndAt;
  final int? lateMinutes;
  final int? earlyLeaveMinutes;
  final int? overtimeMinutes;

  factory AttendanceDrillDownItemDto.fromJson(Map<String, dynamic> json) {
    return AttendanceDrillDownItemDto(
      workReviewId: dtoToString(json['workReviewId']),
      membershipId: dtoToString(json['membershipId']),
      accountId: dtoToString(json['accountId']),
      firstName: dtoToNullableString(json['firstName']),
      lastName: dtoToNullableString(json['lastName']),
      branchId: dtoToString(json['branchId']),
      workDate: dtoToString(json['workDate']),
      classification: dtoToString(json['classification']),
      expectedStartTime: dtoToNullableString(json['expectedStartTime']),
      expectedEndTime: dtoToNullableString(json['expectedEndTime']),
      actualStartAt: dtoToDateTime(json['actualStartAt']),
      actualEndAt: dtoToDateTime(json['actualEndAt']),
      lateMinutes: json['lateMinutes'] == null
          ? null
          : dtoToInt(json['lateMinutes']),
      earlyLeaveMinutes: json['earlyLeaveMinutes'] == null
          ? null
          : dtoToInt(json['earlyLeaveMinutes']),
      overtimeMinutes: json['overtimeMinutes'] == null
          ? null
          : dtoToInt(json['overtimeMinutes']),
    );
  }
}
