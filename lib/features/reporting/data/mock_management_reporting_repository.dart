import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/attendance_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';

final mockManagementReportingRepositoryProvider =
    Provider<ManagementReportingRepository>((ref) {
      return MockManagementReportingRepository();
    });

class MockManagementReportingRepository
    implements ManagementReportingRepository {
  static const _defaultFrom = '2026-03-22';
  static const _defaultTo = '2026-03-22';

  const MockManagementReportingRepository();

  @override
  Future<SalesSummaryReport> getSalesSummary(
    SalesSummaryReportQuery query,
  ) async {
    return SalesSummaryReport(
      scope: _mockScope(query.scope),
      confirmed: const SalesConfirmedMetrics(
        transactionCount: 124,
        totalGrandUsd: 682.5,
        totalGrandKhr: 2802000,
        totalVatUsd: 0,
        totalVatKhr: 0,
        totalDiscountUsd: 12,
        totalDiscountKhr: 49200,
        averageTicketUsd: 5.5,
        averageTicketKhr: 22596.77,
        totalItemsSold: 301,
      ),
      paymentBreakdown: const [
        SalesPaymentBreakdownItem(
          paymentMethod: SalesPaymentMethod.cash,
          transactionCount: 72,
          totalUsd: 341,
          totalKhr: 1398100,
        ),
        SalesPaymentBreakdownItem(
          paymentMethod: SalesPaymentMethod.khqr,
          transactionCount: 52,
          totalUsd: 341.5,
          totalKhr: 1403900,
        ),
      ],
      cashTenderBreakdown: const [
        SalesCashTenderBreakdownItem(
          tenderCurrency: SalesTenderCurrency.usd,
          transactionCount: 61,
          totalTenderAmount: 310,
        ),
        SalesCashTenderBreakdownItem(
          tenderCurrency: SalesTenderCurrency.khr,
          transactionCount: 11,
          totalTenderAmount: 1270000,
        ),
      ],
      saleTypeBreakdown: const [
        SalesTypeBreakdownItem(
          saleType: SalesType.dineIn,
          transactionCount: 56,
          totalUsd: 301,
          totalKhr: 1234100,
          totalItemsSold: 137,
        ),
        SalesTypeBreakdownItem(
          saleType: SalesType.takeaway,
          transactionCount: 63,
          totalUsd: 359.5,
          totalKhr: 1475950,
          totalItemsSold: 154,
        ),
        SalesTypeBreakdownItem(
          saleType: SalesType.delivery,
          transactionCount: 5,
          totalUsd: 22,
          totalKhr: 90250,
          totalItemsSold: 10,
        ),
      ],
      topItems: const [
        SalesTopItem(
          menuItemId: 'menu-item-1',
          itemNameSnapshot: 'Iced Latte',
          quantity: 84,
          revenueUsd: 210,
          revenueKhr: 861000,
        ),
      ],
      categoryBreakdown: const [
        SalesCategoryBreakdownItem(
          categoryNameSnapshot: 'Coffee',
          quantity: 211,
          revenueUsd: 510,
          revenueKhr: 2091000,
        ),
        SalesCategoryBreakdownItem(
          categoryNameSnapshot: 'Uncategorized',
          quantity: 90,
          revenueUsd: 172.5,
          revenueKhr: 711000,
        ),
      ],
      exceptions: const SalesExceptions(
        voidPending: SalesExceptionTotals(
          count: 2,
          totalUsd: 8,
          totalKhr: 32800,
        ),
        voided: SalesExceptionTotals(count: 1, totalUsd: 3.5, totalKhr: 14350),
      ),
    );
  }

  @override
  Future<SalesDrillDownReport> getSalesDrillDown(
    SalesDrillDownReportQuery query,
  ) async {
    return SalesDrillDownReport(
      scope: _mockScope(query.scope),
      items: const [
        SalesDrillDownItem(
          saleId: 'sale-1',
          branchId: 'branch-mock',
          status: SalesRecordStatus.finalized,
          paymentMethod: SalesPaymentMethod.khqr,
          saleType: SalesType.takeaway,
          finalizedAt: null,
          totalItems: 3,
          grandTotalUsd: 7.5,
          grandTotalKhr: 30750,
          vatUsd: 0,
          vatKhr: 0,
          discountUsd: 0,
          discountKhr: 0,
        ),
      ],
      limit: query.limit,
      offset: query.offset,
      total: 1,
      hasMore: false,
    );
  }

  @override
  Future<RestockSpendSummaryReport> getRestockSpendSummary(
    RestockSpendSummaryReportQuery query,
  ) async {
    return RestockSpendSummaryReport(
      scope: _mockScope(query.scope),
      totals: const RestockSpendTotals(
        knownCostSpendUsd: 1420.5,
        knownCostBatchCount: 38,
        unknownCostBatchCount: 4,
      ),
      monthlyBreakdown: const [
        RestockSpendMonthlyBreakdownItem(
          month: '2026-02',
          knownCostSpendUsd: 1420.5,
          knownCostBatchCount: 38,
          unknownCostBatchCount: 4,
        ),
      ],
    );
  }

  @override
  Future<RestockSpendDrillDownReport> getRestockSpendDrillDown(
    RestockSpendDrillDownReportQuery query,
  ) async {
    return RestockSpendDrillDownReport(
      scope: _mockScope(query.scope),
      items: const [
        RestockSpendDrillDownItem(
          restockBatchId: 'restock-1',
          branchId: 'branch-mock',
          stockItemId: 'stock-1',
          stockItemName: 'Milk',
          quantityInBaseUnit: 5000,
          purchaseCostUsd: 15,
          receivedAt: null,
        ),
      ],
      limit: query.limit,
      offset: query.offset,
      total: 1,
      hasMore: false,
    );
  }

  @override
  Future<AttendanceSummaryReport> getAttendanceSummary(
    AttendanceSummaryReportQuery query,
  ) async {
    throw const ApiClientException(
      message: 'Attendance reporting is not available yet.',
      code: 'REPORT_NOT_AVAILABLE',
      statusCode: 503,
    );
  }

  @override
  Future<AttendanceDrillDownReport> getAttendanceDrillDown(
    AttendanceDrillDownReportQuery query,
  ) async {
    throw const ApiClientException(
      message: 'Attendance reporting is not available yet.',
      code: 'REPORT_NOT_AVAILABLE',
      statusCode: 503,
    );
  }

  ReportScope _mockScope(ReportScopeQuery query) {
    return ReportScope(
      tenantId: 'tenant-mock',
      branchScope: query.branchScope,
      branchId: query.branchScope == ReportBranchScope.branch
          ? (query.branchId ?? 'branch-mock')
          : null,
      from: query.from ?? _defaultFrom,
      to: query.to ?? _defaultTo,
      timezone: 'Asia/Phnom_Penh',
      frozenBranchIds: const [],
    );
  }
}
