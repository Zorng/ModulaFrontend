import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/view/sales_summary/sales_summary_page.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

void main() {
  testWidgets('renders top items from the sales summary report', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      repository: const MockManagementReportingRepository(),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Top items'), findsOneWidget);
    expect(find.text('Iced Latte'), findsOneWidget);
    expect(find.text('Qty 84'), findsOneWidget);
  });

  testWidgets('renders an unavailable state when sales summary load fails', (
    tester,
  ) async {
    await _pumpPage(tester, repository: const _ErrorSalesSummaryRepository());
    await tester.pumpAndSettle();

    expect(find.text('Sales summary unavailable'), findsOneWidget);
    expect(find.text('Sales service unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Revenue'), findsNothing);
  });

  testWidgets('renders a no-data state when the summary is empty', (
    tester,
  ) async {
    await _pumpPage(tester, repository: const _EmptySalesSummaryRepository());
    await tester.pumpAndSettle();

    expect(find.text('No sales data'), findsOneWidget);
    expect(
      find.text(
        'No sales matched the current filters for the selected period.',
      ),
      findsOneWidget,
    );
    expect(find.text('Revenue'), findsNothing);
    expect(find.text('View Sales Details'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required ManagementReportingRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        managementReportingRepositoryProvider.overrideWithValue(repository),
        reportingAccessContextProvider.overrideWithValue(
          const ReportingAccessContext(
            role: AuthRole.admin,
            tenantId: 'tenant-1',
            activeBranchId: 'branch-1',
            branches: [ReportingBranchOption(id: 'branch-1', name: 'Main')],
          ),
        ),
        branchControllerProvider.overrideWith(
          () => _StaticBranchController(
            const BranchState(
              branches: [
                BranchListItem(
                  branchId: 'branch-1',
                  tenantId: 'tenant-1',
                  branchName: 'Main',
                  status: 'ACTIVE',
                ),
              ],
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: SalesSummaryPage())),
    ),
  );
}

class _StaticBranchController extends BranchController {
  _StaticBranchController(this._initialState);

  final BranchState _initialState;

  @override
  BranchState build() => _initialState;

  @override
  Future<void> loadInitial() async {}
}

class _ErrorSalesSummaryRepository extends MockManagementReportingRepository {
  const _ErrorSalesSummaryRepository();

  @override
  Future<SalesSummaryReport> getSalesSummary(SalesSummaryReportQuery query) {
    throw const ApiClientException(
      message: 'Sales service unavailable.',
      code: 'REPORT_SERVICE_UNAVAILABLE',
      statusCode: 503,
    );
  }
}

class _EmptySalesSummaryRepository extends MockManagementReportingRepository {
  const _EmptySalesSummaryRepository();

  @override
  Future<SalesSummaryReport> getSalesSummary(
    SalesSummaryReportQuery query,
  ) async {
    return SalesSummaryReport(
      scope: ReportScope(
        tenantId: 'tenant-1',
        branchScope: query.scope.branchScope,
        branchId: query.scope.branchId,
        from: query.scope.from ?? '2026-03-25',
        to: query.scope.to ?? '2026-03-25',
        timezone: 'Asia/Phnom_Penh',
        frozenBranchIds: const [],
      ),
      confirmed: const SalesConfirmedMetrics(
        transactionCount: 0,
        totalGrandUsd: 0,
        totalGrandKhr: 0,
        totalVatUsd: 0,
        totalVatKhr: 0,
        totalDiscountUsd: 0,
        totalDiscountKhr: 0,
        averageTicketUsd: 0,
        averageTicketKhr: 0,
        totalItemsSold: 0,
      ),
      paymentBreakdown: const [],
      cashTenderBreakdown: const [],
      saleTypeBreakdown: const [],
      topItems: const [],
      categoryBreakdown: const [],
      exceptions: const SalesExceptions(
        voidPending: SalesExceptionTotals(count: 0, totalUsd: 0, totalKhr: 0),
        voided: SalesExceptionTotals(count: 0, totalUsd: 0, totalKhr: 0),
      ),
    );
  }
}
