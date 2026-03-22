import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/reporting/data/dto/attendance_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/report_scope_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/restock_spend_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/sales_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_api.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/attendance_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';

final remoteManagementReportingRepositoryProvider =
    Provider<ManagementReportingRepository>((ref) {
      final api = ref.watch(managementReportingApiProvider);
      return RemoteManagementReportingRepository(api);
    });

class RemoteManagementReportingRepository
    implements ManagementReportingRepository {
  RemoteManagementReportingRepository(this._api);

  final ManagementReportingApi _api;

  @override
  Future<SalesSummaryReport> getSalesSummary(
    SalesSummaryReportQuery query,
  ) async {
    final dto = await _api.fetchSalesSummary(query);
    return _mapSalesSummary(dto);
  }

  @override
  Future<SalesDrillDownReport> getSalesDrillDown(
    SalesDrillDownReportQuery query,
  ) async {
    final dto = await _api.fetchSalesDrillDown(query);
    return _mapSalesDrillDown(dto);
  }

  @override
  Future<RestockSpendSummaryReport> getRestockSpendSummary(
    RestockSpendSummaryReportQuery query,
  ) async {
    final dto = await _api.fetchRestockSpendSummary(query);
    return _mapRestockSpendSummary(dto);
  }

  @override
  Future<RestockSpendDrillDownReport> getRestockSpendDrillDown(
    RestockSpendDrillDownReportQuery query,
  ) async {
    final dto = await _api.fetchRestockSpendDrillDown(query);
    return _mapRestockSpendDrillDown(dto);
  }

  @override
  Future<AttendanceSummaryReport> getAttendanceSummary(
    AttendanceSummaryReportQuery query,
  ) async {
    final dto = await _api.fetchAttendanceSummary(query);
    return _mapAttendanceSummary(dto);
  }

  @override
  Future<AttendanceDrillDownReport> getAttendanceDrillDown(
    AttendanceDrillDownReportQuery query,
  ) async {
    final dto = await _api.fetchAttendanceDrillDown(query);
    return _mapAttendanceDrillDown(dto);
  }
}

ReportScope _mapScope(ReportScopeDto dto) {
  return ReportScope(
    tenantId: dto.tenantId,
    branchScope: reportBranchScopeFromApi(dto.branchScope),
    branchId: dto.branchId,
    from: dto.from,
    to: dto.to,
    timezone: dto.timezone,
    frozenBranchIds: dto.frozenBranchIds,
  );
}

SalesSummaryReport _mapSalesSummary(SalesSummaryReportDto dto) {
  return SalesSummaryReport(
    scope: _mapScope(dto.scope),
    confirmed: SalesConfirmedMetrics(
      transactionCount: dto.confirmed.transactionCount,
      totalGrandUsd: dto.confirmed.totalGrandUsd,
      totalGrandKhr: dto.confirmed.totalGrandKhr,
      totalVatUsd: dto.confirmed.totalVatUsd,
      totalVatKhr: dto.confirmed.totalVatKhr,
      totalDiscountUsd: dto.confirmed.totalDiscountUsd,
      totalDiscountKhr: dto.confirmed.totalDiscountKhr,
      averageTicketUsd: dto.confirmed.averageTicketUsd,
      averageTicketKhr: dto.confirmed.averageTicketKhr,
      totalItemsSold: dto.confirmed.totalItemsSold,
    ),
    paymentBreakdown: dto.paymentBreakdown
        .map(
          (item) => SalesPaymentBreakdownItem(
            paymentMethod: salesPaymentMethodFromApi(item.paymentMethod),
            transactionCount: item.transactionCount,
            totalUsd: item.totalUsd,
            totalKhr: item.totalKhr,
          ),
        )
        .toList(growable: false),
    cashTenderBreakdown: dto.cashTenderBreakdown
        .map(
          (item) => SalesCashTenderBreakdownItem(
            tenderCurrency: salesTenderCurrencyFromApi(item.tenderCurrency),
            transactionCount: item.transactionCount,
            totalTenderAmount: item.totalTenderAmount,
          ),
        )
        .toList(growable: false),
    saleTypeBreakdown: dto.saleTypeBreakdown
        .map(
          (item) => SalesTypeBreakdownItem(
            saleType: salesTypeFromApi(item.saleType),
            transactionCount: item.transactionCount,
            totalUsd: item.totalUsd,
            totalKhr: item.totalKhr,
            totalItemsSold: item.totalItemsSold,
          ),
        )
        .toList(growable: false),
    topItems: dto.topItems
        .map(
          (item) => SalesTopItem(
            menuItemId: item.menuItemId,
            itemNameSnapshot: item.itemNameSnapshot,
            quantity: item.quantity,
            revenueUsd: item.revenueUsd,
            revenueKhr: item.revenueKhr,
          ),
        )
        .toList(growable: false),
    categoryBreakdown: dto.categoryBreakdown
        .map(
          (item) => SalesCategoryBreakdownItem(
            categoryNameSnapshot: item.categoryNameSnapshot,
            quantity: item.quantity,
            revenueUsd: item.revenueUsd,
            revenueKhr: item.revenueKhr,
          ),
        )
        .toList(growable: false),
    exceptions: SalesExceptions(
      voidPending: SalesExceptionTotals(
        count: dto.exceptions.voidPending.count,
        totalUsd: dto.exceptions.voidPending.totalUsd,
        totalKhr: dto.exceptions.voidPending.totalKhr,
      ),
      voided: SalesExceptionTotals(
        count: dto.exceptions.voided.count,
        totalUsd: dto.exceptions.voided.totalUsd,
        totalKhr: dto.exceptions.voided.totalKhr,
      ),
    ),
  );
}

SalesDrillDownReport _mapSalesDrillDown(SalesDrillDownReportDto dto) {
  return SalesDrillDownReport(
    scope: _mapScope(dto.scope),
    items: dto.items
        .map(
          (item) => SalesDrillDownItem(
            saleId: item.saleId,
            branchId: item.branchId,
            status: salesRecordStatusFromApi(item.status),
            paymentMethod: salesPaymentMethodFromApi(item.paymentMethod),
            saleType: salesTypeFromApi(item.saleType),
            finalizedAt: item.finalizedAt,
            totalItems: item.totalItems,
            grandTotalUsd: item.grandTotalUsd,
            grandTotalKhr: item.grandTotalKhr,
            vatUsd: item.vatUsd,
            vatKhr: item.vatKhr,
            discountUsd: item.discountUsd,
            discountKhr: item.discountKhr,
          ),
        )
        .toList(growable: false),
    limit: dto.limit,
    offset: dto.offset,
    total: dto.total,
    hasMore: dto.hasMore,
  );
}

RestockSpendSummaryReport _mapRestockSpendSummary(
  RestockSpendSummaryReportDto dto,
) {
  return RestockSpendSummaryReport(
    scope: _mapScope(dto.scope),
    totals: RestockSpendTotals(
      knownCostSpendUsd: dto.totals.knownCostSpendUsd,
      knownCostBatchCount: dto.totals.knownCostBatchCount,
      unknownCostBatchCount: dto.totals.unknownCostBatchCount,
    ),
    monthlyBreakdown: dto.monthlyBreakdown
        .map(
          (item) => RestockSpendMonthlyBreakdownItem(
            month: item.month,
            knownCostSpendUsd: item.knownCostSpendUsd,
            knownCostBatchCount: item.knownCostBatchCount,
            unknownCostBatchCount: item.unknownCostBatchCount,
          ),
        )
        .toList(growable: false),
  );
}

RestockSpendDrillDownReport _mapRestockSpendDrillDown(
  RestockSpendDrillDownReportDto dto,
) {
  return RestockSpendDrillDownReport(
    scope: _mapScope(dto.scope),
    items: dto.items
        .map(
          (item) => RestockSpendDrillDownItem(
            restockBatchId: item.restockBatchId,
            branchId: item.branchId,
            stockItemId: item.stockItemId,
            stockItemName: item.stockItemName,
            quantityInBaseUnit: item.quantityInBaseUnit,
            purchaseCostUsd: item.purchaseCostUsd,
            receivedAt: item.receivedAt,
          ),
        )
        .toList(growable: false),
    limit: dto.limit,
    offset: dto.offset,
    total: dto.total,
    hasMore: dto.hasMore,
  );
}

AttendanceSummaryReport _mapAttendanceSummary(AttendanceSummaryReportDto dto) {
  return AttendanceSummaryReport(
    scope: _mapScope(dto.scope),
    planningCoverage: attendancePlanningCoverageFromApi(dto.planningCoverage),
    branchTotals: AttendanceBranchTotals(
      plannedShiftCount: dto.branchTotals.plannedShiftCount,
      attendedCount: dto.branchTotals.attendedCount,
      classificationCounts: _mapAttendanceClassificationCounts(
        dto.branchTotals.classificationCounts,
      ),
      totalScheduledHours: dto.branchTotals.totalScheduledHours,
      totalWorkedHours: dto.branchTotals.totalWorkedHours,
      totalLateMinutes: dto.branchTotals.totalLateMinutes,
      totalEarlyLeaveMinutes: dto.branchTotals.totalEarlyLeaveMinutes,
      totalOvertimeMinutes: dto.branchTotals.totalOvertimeMinutes,
    ),
    perStaff: dto.perStaff
        .map(
          (item) => AttendanceStaffSummary(
            membershipId: item.membershipId,
            accountId: item.accountId,
            firstName: item.firstName,
            lastName: item.lastName,
            plannedShiftCount: item.plannedShiftCount,
            attendedCount: item.attendedCount,
            classificationCounts: _mapAttendanceClassificationCounts(
              item.classificationCounts,
            ),
            totalScheduledHours: item.totalScheduledHours,
            totalWorkedHours: item.totalWorkedHours,
            totalLateMinutes: item.totalLateMinutes,
            totalEarlyLeaveMinutes: item.totalEarlyLeaveMinutes,
            totalOvertimeMinutes: item.totalOvertimeMinutes,
            planningCoverage: attendancePlanningCoverageFromApi(
              item.planningCoverage,
            ),
          ),
        )
        .toList(growable: false),
  );
}

AttendanceDrillDownReport _mapAttendanceDrillDown(
  AttendanceDrillDownReportDto dto,
) {
  return AttendanceDrillDownReport(
    scope: _mapScope(dto.scope),
    items: dto.items
        .map(
          (item) => AttendanceDrillDownItem(
            workReviewId: item.workReviewId,
            membershipId: item.membershipId,
            accountId: item.accountId,
            firstName: item.firstName,
            lastName: item.lastName,
            branchId: item.branchId,
            workDate: item.workDate,
            classification: attendanceRecordClassificationFromApi(
              item.classification,
            ),
            expectedStartTime: item.expectedStartTime,
            expectedEndTime: item.expectedEndTime,
            actualStartAt: item.actualStartAt,
            actualEndAt: item.actualEndAt,
            lateMinutes: item.lateMinutes,
            earlyLeaveMinutes: item.earlyLeaveMinutes,
            overtimeMinutes: item.overtimeMinutes,
          ),
        )
        .toList(growable: false),
    limit: dto.limit,
    offset: dto.offset,
  );
}

AttendanceClassificationCounts _mapAttendanceClassificationCounts(
  AttendanceClassificationCountsDto dto,
) {
  return AttendanceClassificationCounts(
    onTime: dto.onTime,
    late: dto.late,
    earlyLeave: dto.earlyLeave,
    absent: dto.absent,
    overtime: dto.overtime,
    unscheduledWork: dto.unscheduledWork,
    incompleteRecord: dto.incompleteRecord,
  );
}
