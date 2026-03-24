import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';

enum ReportTimeWindow { day, week, month, custom }

ReportTimeWindow reportTimeWindowFromApi(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'week':
      return ReportTimeWindow.week;
    case 'month':
      return ReportTimeWindow.month;
    case 'custom':
      return ReportTimeWindow.custom;
    case 'day':
    default:
      return ReportTimeWindow.day;
  }
}

String reportTimeWindowToApi(ReportTimeWindow value) {
  switch (value) {
    case ReportTimeWindow.day:
      return 'day';
    case ReportTimeWindow.week:
      return 'week';
    case ReportTimeWindow.month:
      return 'month';
    case ReportTimeWindow.custom:
      return 'custom';
  }
}

class ReportScopeQuery {
  const ReportScopeQuery({
    this.window = ReportTimeWindow.day,
    this.from,
    this.to,
    this.branchScope = ReportBranchScope.branch,
    this.branchId,
  });

  final ReportTimeWindow window;
  final String? from;
  final String? to;
  final ReportBranchScope branchScope;
  final String? branchId;
}

enum SalesDrillDownStatusFilter { all, finalized, voidPending, voided }

String salesDrillDownStatusFilterToApi(SalesDrillDownStatusFilter value) {
  switch (value) {
    case SalesDrillDownStatusFilter.all:
      return 'ALL';
    case SalesDrillDownStatusFilter.finalized:
      return 'FINALIZED';
    case SalesDrillDownStatusFilter.voidPending:
      return 'VOID_PENDING';
    case SalesDrillDownStatusFilter.voided:
      return 'VOIDED';
  }
}

class SalesSummaryReportQuery {
  const SalesSummaryReportQuery({required this.scope, this.topN = 10});

  final ReportScopeQuery scope;
  final int topN;
}

class SalesDrillDownReportQuery {
  const SalesDrillDownReportQuery({
    required this.scope,
    this.status = SalesDrillDownStatusFilter.all,
    this.limit = 50,
    this.offset = 0,
  });

  final ReportScopeQuery scope;
  final SalesDrillDownStatusFilter status;
  final int limit;
  final int offset;
}

enum RestockSpendCostFilter { all, known, unknown }

String restockSpendCostFilterToApi(RestockSpendCostFilter value) {
  switch (value) {
    case RestockSpendCostFilter.all:
      return 'ALL';
    case RestockSpendCostFilter.known:
      return 'KNOWN';
    case RestockSpendCostFilter.unknown:
      return 'UNKNOWN';
  }
}

class RestockSpendSummaryReportQuery {
  const RestockSpendSummaryReportQuery({required this.scope});

  final ReportScopeQuery scope;
}

class RestockSpendDrillDownReportQuery {
  const RestockSpendDrillDownReportQuery({
    required this.scope,
    this.costFilter = RestockSpendCostFilter.all,
    this.limit = 50,
    this.offset = 0,
  });

  final ReportScopeQuery scope;
  final RestockSpendCostFilter costFilter;
  final int limit;
  final int offset;
}

enum AttendanceClassificationFilter {
  onTime,
  late,
  earlyLeave,
  absent,
  overtime,
  unscheduledWork,
  incompleteRecord,
}

String attendanceClassificationFilterToApi(
  AttendanceClassificationFilter value,
) {
  switch (value) {
    case AttendanceClassificationFilter.onTime:
      return 'ON_TIME';
    case AttendanceClassificationFilter.late:
      return 'LATE';
    case AttendanceClassificationFilter.earlyLeave:
      return 'EARLY_LEAVE';
    case AttendanceClassificationFilter.absent:
      return 'ABSENT';
    case AttendanceClassificationFilter.overtime:
      return 'OVERTIME';
    case AttendanceClassificationFilter.unscheduledWork:
      return 'UNSCHEDULED_WORK';
    case AttendanceClassificationFilter.incompleteRecord:
      return 'INCOMPLETE_RECORD';
  }
}

class AttendanceSummaryReportQuery {
  const AttendanceSummaryReportQuery({required this.scope, this.membershipId});

  final ReportScopeQuery scope;
  final String? membershipId;
}

class AttendanceDrillDownReportQuery {
  const AttendanceDrillDownReportQuery({
    required this.scope,
    this.membershipId,
    this.classification,
    this.limit = 50,
    this.offset = 0,
  });

  final ReportScopeQuery scope;
  final String? membershipId;
  final AttendanceClassificationFilter? classification;
  final int limit;
  final int offset;
}
