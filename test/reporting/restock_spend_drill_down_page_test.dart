import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/view/restock_spend_drill_down/restock_spend_drill_down_page.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

void main() {
  testWidgets('renders restock drill-down on narrow screens without overflow', (
    tester,
  ) async {
    _setScreenSize(tester, const Size(390, 844));

    await _pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Restock Details'), findsOneWidget);
    expect(find.textContaining('Coconut Milk'), findsOneWidget);
    expect(find.text('Branch Downtown Branch'), findsOneWidget);
    expect(find.textContaining('branch-mock-with-long-name'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders restock drill-down on wide screens without overflow', (
    tester,
  ) async {
    _setScreenSize(tester, const Size(1280, 800));

    await _pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Restock Details'), findsOneWidget);
    expect(find.text('Showing 1 of 1 records'), findsOneWidget);
    expect(find.textContaining('Coconut Milk'), findsOneWidget);
    expect(find.text('Branch Downtown Branch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders unknown cost as a chip instead of plain text', (
    tester,
  ) async {
    _setScreenSize(tester, const Size(1280, 800));

    await _pumpPage(
      tester,
      repository: const _ResponsiveRestockRepository(purchaseCostUsd: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unknown cost'), findsWidgets);
    expect(find.text('Purchase cost'), findsNothing);
    expect(find.text('Unknown'), findsNothing);
  });

  testWidgets('uses branch name from route args when lookup is unavailable', (
    tester,
  ) async {
    _setScreenSize(tester, const Size(430, 844));

    await _pumpPage(
      tester,
      accessContext: null,
      args: RestockSpendDrillDownRouteArgs(
        scope: ReportScopeQuery(
          branchScope: ReportBranchScope.branch,
          branchId: 'branch-mock-with-long-name',
        ),
        branchName: 'Fallback Branch',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Branch Fallback Branch'), findsOneWidget);
    expect(find.textContaining('branch-mock-with-long-name'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  ManagementReportingRepository repository =
      const _ResponsiveRestockRepository(),
  ReportingAccessContext? accessContext = const ReportingAccessContext(
    role: AuthRole.admin,
    tenantId: 'tenant-1',
    activeBranchId: 'branch-1',
    branches: [
      ReportingBranchOption(
        id: 'branch-mock-with-long-name',
        name: 'Downtown Branch',
      ),
    ],
  ),
  RestockSpendDrillDownRouteArgs? args,
}) async {
  final effectiveArgs =
      args ??
      RestockSpendDrillDownRouteArgs(
        scope: const ReportScopeQuery(
          branchScope: ReportBranchScope.branch,
          branchId: 'branch-1',
        ),
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        managementReportingRepositoryProvider.overrideWithValue(repository),
        if (accessContext != null)
          reportingAccessContextProvider.overrideWithValue(accessContext),
      ],
      child: MaterialApp(home: RestockSpendDrillDownPage(args: effectiveArgs)),
    ),
  );
}

void _setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _ResponsiveRestockRepository extends MockManagementReportingRepository {
  const _ResponsiveRestockRepository({this.purchaseCostUsd = 1250.75});

  final double? purchaseCostUsd;

  @override
  Future<RestockSpendDrillDownReport> getRestockSpendDrillDown(
    RestockSpendDrillDownReportQuery query,
  ) async {
    return RestockSpendDrillDownReport(
      scope: ReportScope(
        tenantId: 'tenant-mock',
        branchScope: query.scope.branchScope,
        branchId: query.scope.branchId,
        from: query.scope.from ?? '2026-03-22',
        to: query.scope.to ?? '2026-03-22',
        timezone: 'Asia/Phnom_Penh',
        frozenBranchIds: const [],
      ),
      items: [
        RestockSpendDrillDownItem(
          restockBatchId: 'restock-batch-with-a-very-long-identifier',
          branchId: 'branch-mock-with-long-name',
          stockItemId: 'stock-1',
          stockItemName:
              'Coconut Milk Extra Large Commercial Kitchen Supply Refill Pack',
          quantityInBaseUnit: 12500,
          purchaseCostUsd: purchaseCostUsd,
          receivedAt: null,
        ),
      ],
      limit: query.limit,
      offset: query.offset,
      total: 1,
      hasMore: false,
    );
  }
}
