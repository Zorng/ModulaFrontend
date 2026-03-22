import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/reporting/data/dto/attendance_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/restock_spend_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/sales_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_api.dart';
import 'package:modular_pos/features/reporting/data/remote_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/attendance_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';

class _FakeManagementReportingApi extends ManagementReportingApi {
  _FakeManagementReportingApi() : super(Dio());

  @override
  Future<SalesSummaryReportDto> fetchSalesSummary(
    SalesSummaryReportQuery query,
  ) async {
    return SalesSummaryReportDto.fromJson(_salesSummaryPayload);
  }

  @override
  Future<SalesDrillDownReportDto> fetchSalesDrillDown(
    SalesDrillDownReportQuery query,
  ) async {
    return SalesDrillDownReportDto.fromJson(_salesDrillDownPayload);
  }

  @override
  Future<RestockSpendSummaryReportDto> fetchRestockSpendSummary(
    RestockSpendSummaryReportQuery query,
  ) async {
    return RestockSpendSummaryReportDto.fromJson(_restockSummaryPayload);
  }

  @override
  Future<AttendanceSummaryReportDto> fetchAttendanceSummary(
    AttendanceSummaryReportQuery query,
  ) async {
    return AttendanceSummaryReportDto.fromJson(_attendanceSummaryPayload);
  }
}

const _salesSummaryPayload = <String, dynamic>{
  'scope': {
    'tenantId': 'tenant-1',
    'branchScope': 'BRANCH',
    'branchId': 'branch-1',
    'from': '2026-02-01',
    'to': '2026-02-29',
    'timezone': 'Asia/Phnom_Penh',
    'frozenBranchIds': ['branch-frozen'],
  },
  'confirmed': {
    'transactionCount': 124,
    'totalGrandUsd': 682.5,
    'totalGrandKhr': 2802000,
    'totalVatUsd': 0,
    'totalVatKhr': 0,
    'totalDiscountUsd': 12,
    'totalDiscountKhr': 49200,
    'averageTicketUsd': 5.5,
    'averageTicketKhr': 22596.77,
    'totalItemsSold': 301,
  },
  'paymentBreakdown': [
    {
      'paymentMethod': 'CASH',
      'transactionCount': 72,
      'totalUsd': 341,
      'totalKhr': 1398100,
    },
  ],
  'cashTenderBreakdown': [
    {'tenderCurrency': 'USD', 'transactionCount': 61, 'totalTenderAmount': 310},
  ],
  'saleTypeBreakdown': [
    {
      'saleType': 'TAKEAWAY',
      'transactionCount': 63,
      'totalUsd': 359.5,
      'totalKhr': 1475950,
      'totalItemsSold': 154,
    },
  ],
  'topItems': [
    {
      'menuItemId': 'item-1',
      'itemNameSnapshot': 'Iced Latte',
      'quantity': 84,
      'revenueUsd': 210,
      'revenueKhr': 861000,
    },
  ],
  'categoryBreakdown': [
    {
      'categoryNameSnapshot': 'Coffee',
      'quantity': 211,
      'revenueUsd': 510,
      'revenueKhr': 2091000,
    },
  ],
  'exceptions': {
    'voidPending': {'count': 2, 'totalUsd': 8, 'totalKhr': 32800},
    'voided': {'count': 1, 'totalUsd': 3.5, 'totalKhr': 14350},
  },
};

const _salesDrillDownPayload = <String, dynamic>{
  'scope': {
    'tenantId': 'tenant-1',
    'branchScope': 'BRANCH',
    'branchId': 'branch-1',
    'from': '2026-02-01',
    'to': '2026-02-29',
    'timezone': 'Asia/Phnom_Penh',
    'frozenBranchIds': [],
  },
  'items': [
    {
      'saleId': 'sale-1',
      'branchId': 'branch-1',
      'status': 'FINALIZED',
      'paymentMethod': 'KHQR',
      'saleType': 'TAKEAWAY',
      'finalizedAt': '2026-02-24T04:11:15.814Z',
      'totalItems': 3,
      'grandTotalUsd': 7.5,
      'grandTotalKhr': 30750,
      'vatUsd': 0,
      'vatKhr': 0,
      'discountUsd': 0,
      'discountKhr': 0,
    },
  ],
  'limit': 50,
  'offset': 0,
  'total': 1,
  'hasMore': false,
};

const _restockSummaryPayload = <String, dynamic>{
  'scope': {
    'tenantId': 'tenant-1',
    'branchScope': 'ALL_BRANCHES',
    'branchId': null,
    'from': '2026-02-01',
    'to': '2026-02-29',
    'timezone': 'Asia/Phnom_Penh',
    'frozenBranchIds': [],
  },
  'totals': {
    'knownCostSpendUsd': 1420.5,
    'knownCostBatchCount': 38,
    'unknownCostBatchCount': 4,
  },
  'monthlyBreakdown': [
    {
      'month': '2026-02',
      'knownCostSpendUsd': 1420.5,
      'knownCostBatchCount': 38,
      'unknownCostBatchCount': 4,
    },
  ],
};

const _attendanceSummaryPayload = <String, dynamic>{
  'scope': {
    'tenantId': 'tenant-1',
    'branchScope': 'BRANCH',
    'branchId': 'branch-1',
    'from': '2026-02-01',
    'to': '2026-02-29',
    'timezone': 'Asia/Phnom_Penh',
    'frozenBranchIds': [],
  },
  'planningCoverage': 'FULL',
  'branchTotals': {
    'plannedShiftCount': 188,
    'attendedCount': 182,
    'classificationCounts': {
      'onTime': 120,
      'late': 14,
      'earlyLeave': 3,
      'absent': 6,
      'overtime': 11,
      'unscheduledWork': 2,
      'incompleteRecord': 1,
    },
    'totalScheduledHours': 1504,
    'totalWorkedHours': 1481.5,
    'totalLateMinutes': 163,
    'totalEarlyLeaveMinutes': 47,
    'totalOvertimeMinutes': 221,
  },
  'perStaff': [
    {
      'membershipId': 'membership-1',
      'accountId': 'account-1',
      'firstName': 'Dula',
      'lastName': 'Owner',
      'plannedShiftCount': 20,
      'attendedCount': 18,
      'classificationCounts': {
        'onTime': 14,
        'late': 2,
        'earlyLeave': 0,
        'absent': 1,
        'overtime': 1,
        'unscheduledWork': 0,
        'incompleteRecord': 0,
      },
      'totalScheduledHours': 160,
      'totalWorkedHours': 154.5,
      'totalLateMinutes': 12,
      'totalEarlyLeaveMinutes': 0,
      'totalOvertimeMinutes': 8,
      'planningCoverage': 'FULL',
    },
  ],
};

void main() {
  group('Management reporting DTO parsing', () {
    test('parses sales summary payload', () {
      final dto = SalesSummaryReportDto.fromJson(_salesSummaryPayload);

      expect(dto.scope.branchScope, 'BRANCH');
      expect(dto.confirmed.transactionCount, 124);
      expect(dto.paymentBreakdown.first.paymentMethod, 'CASH');
      expect(dto.exceptions.voidPending.count, 2);
    });

    test('parses restock summary payload', () {
      final dto = RestockSpendSummaryReportDto.fromJson(_restockSummaryPayload);

      expect(dto.scope.branchId, isNull);
      expect(dto.totals.knownCostSpendUsd, 1420.5);
      expect(dto.monthlyBreakdown.first.month, '2026-02');
    });

    test('parses attendance summary payload', () {
      final dto = AttendanceSummaryReportDto.fromJson(
        _attendanceSummaryPayload,
      );

      expect(dto.planningCoverage, 'FULL');
      expect(dto.branchTotals.attendedCount, 182);
      expect(dto.perStaff.first.firstName, 'Dula');
    });
  });

  group('Management reporting repository mapping', () {
    final repository = RemoteManagementReportingRepository(
      _FakeManagementReportingApi(),
    );

    test('maps sales summary into domain models', () async {
      final report = await repository.getSalesSummary(
        const SalesSummaryReportQuery(
          scope: ReportScopeQuery(branchId: 'branch-1'),
        ),
      );

      expect(report, isA<SalesSummaryReport>());
      expect(report.scope.branchScope, ReportBranchScope.branch);
      expect(
        report.paymentBreakdown.first.paymentMethod,
        SalesPaymentMethod.cash,
      );
      expect(report.saleTypeBreakdown.first.saleType, SalesType.takeaway);
    });

    test('maps sales drill-down into domain models', () async {
      final report = await repository.getSalesDrillDown(
        const SalesDrillDownReportQuery(
          scope: ReportScopeQuery(branchId: 'branch-1'),
        ),
      );

      expect(report.items, hasLength(1));
      expect(report.items.first.status, SalesRecordStatus.finalized);
      expect(report.items.first.paymentMethod, SalesPaymentMethod.khqr);
    });

    test('maps restock summary into domain models', () async {
      final report = await repository.getRestockSpendSummary(
        const RestockSpendSummaryReportQuery(
          scope: ReportScopeQuery(branchScope: ReportBranchScope.allBranches),
        ),
      );

      expect(report, isA<RestockSpendSummaryReport>());
      expect(report.scope.branchScope, ReportBranchScope.allBranches);
      expect(report.monthlyBreakdown.first.unknownCostBatchCount, 4);
    });

    test('maps attendance summary into domain models', () async {
      final report = await repository.getAttendanceSummary(
        const AttendanceSummaryReportQuery(
          scope: ReportScopeQuery(branchId: 'branch-1'),
        ),
      );

      expect(report, isA<AttendanceSummaryReport>());
      expect(report.planningCoverage, AttendancePlanningCoverage.full);
      expect(
        report.perStaff.first.planningCoverage,
        AttendancePlanningCoverage.full,
      );
    });
  });

  group('Management reporting error model', () {
    test('supports attendance unavailable reason code shape', () {
      const error = ApiClientException(
        message: 'Attendance reporting is not available yet.',
        code: 'REPORT_NOT_AVAILABLE',
        statusCode: 503,
      );

      expect(error.code, 'REPORT_NOT_AVAILABLE');
      expect(error.statusCode, 503);
    });
  });
}
