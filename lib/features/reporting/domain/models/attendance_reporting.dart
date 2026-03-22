import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';

enum AttendancePlanningCoverage { full, partialOrMissing, unknown }

AttendancePlanningCoverage attendancePlanningCoverageFromApi(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'FULL':
      return AttendancePlanningCoverage.full;
    case 'PARTIAL_OR_MISSING':
      return AttendancePlanningCoverage.partialOrMissing;
    default:
      return AttendancePlanningCoverage.unknown;
  }
}

enum AttendanceRecordClassification {
  onTime,
  late,
  earlyLeave,
  absent,
  overtime,
  unscheduledWork,
  incompleteRecord,
  unknown,
}

AttendanceRecordClassification attendanceRecordClassificationFromApi(
  String? raw,
) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'ON_TIME':
      return AttendanceRecordClassification.onTime;
    case 'LATE':
      return AttendanceRecordClassification.late;
    case 'EARLY_LEAVE':
      return AttendanceRecordClassification.earlyLeave;
    case 'ABSENT':
      return AttendanceRecordClassification.absent;
    case 'OVERTIME':
      return AttendanceRecordClassification.overtime;
    case 'UNSCHEDULED_WORK':
      return AttendanceRecordClassification.unscheduledWork;
    case 'INCOMPLETE_RECORD':
      return AttendanceRecordClassification.incompleteRecord;
    default:
      return AttendanceRecordClassification.unknown;
  }
}

class AttendanceClassificationCounts {
  const AttendanceClassificationCounts({
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
}

class AttendanceBranchTotals {
  const AttendanceBranchTotals({
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
  final AttendanceClassificationCounts classificationCounts;
  final double? totalScheduledHours;
  final double totalWorkedHours;
  final int totalLateMinutes;
  final int totalEarlyLeaveMinutes;
  final int totalOvertimeMinutes;
}

class AttendanceStaffSummary {
  const AttendanceStaffSummary({
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
  final AttendanceClassificationCounts classificationCounts;
  final double? totalScheduledHours;
  final double totalWorkedHours;
  final int totalLateMinutes;
  final int totalEarlyLeaveMinutes;
  final int totalOvertimeMinutes;
  final AttendancePlanningCoverage planningCoverage;
}

class AttendanceSummaryReport {
  const AttendanceSummaryReport({
    required this.scope,
    required this.planningCoverage,
    required this.branchTotals,
    required this.perStaff,
  });

  final ReportScope scope;
  final AttendancePlanningCoverage planningCoverage;
  final AttendanceBranchTotals branchTotals;
  final List<AttendanceStaffSummary> perStaff;
}

class AttendanceDrillDownReport {
  const AttendanceDrillDownReport({
    required this.scope,
    required this.items,
    required this.limit,
    required this.offset,
  });

  final ReportScope scope;
  final List<AttendanceDrillDownItem> items;
  final int limit;
  final int offset;
}

class AttendanceDrillDownItem {
  const AttendanceDrillDownItem({
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
  final AttendanceRecordClassification classification;
  final String? expectedStartTime;
  final String? expectedEndTime;
  final DateTime? actualStartAt;
  final DateTime? actualEndAt;
  final int? lateMinutes;
  final int? earlyLeaveMinutes;
  final int? overtimeMinutes;
}
