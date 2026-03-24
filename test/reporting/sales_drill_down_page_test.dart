import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/view/sales_drill_down/sales_drill_down_page.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

void main() {
  testWidgets('scrolls the filter container with the sales list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
          reportingAccessContextProvider.overrideWithValue(
            const ReportingAccessContext(
              role: AuthRole.admin,
              tenantId: 'tenant-1',
              activeBranchId: 'branch-mock',
              branches: [
                ReportingBranchOption(id: 'branch-mock', name: 'Main Branch'),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: SalesDrillDownPage(
            args: SalesDrillDownRouteArgs(
              scope: ReportScopeQuery(
                branchScope: ReportBranchScope.branch,
                branchId: 'branch-1',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final currentFilterFinder = find.text('Current filter');
    final beforeScroll = tester.getTopLeft(currentFilterFinder).dy;

    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();

    final afterScroll = tester.getTopLeft(currentFilterFinder).dy;
    expect(afterScroll, lessThan(beforeScroll));
  });

  testWidgets('renders sales drill-down records from reporting state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
          reportingAccessContextProvider.overrideWithValue(
            const ReportingAccessContext(
              role: AuthRole.admin,
              tenantId: 'tenant-1',
              activeBranchId: 'branch-mock',
              branches: [
                ReportingBranchOption(id: 'branch-mock', name: 'Main Branch'),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: SalesDrillDownPage(
            args: SalesDrillDownRouteArgs(
              scope: ReportScopeQuery(
                branchScope: ReportBranchScope.branch,
                branchId: 'branch-1',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sales Details'), findsOneWidget);
    expect(find.text('Current filter'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Main Branch'), findsWidgets);
    expect(find.text('sale-1'), findsNothing);
    expect(find.text('Takeaway'), findsOneWidget);
    expect(find.text('KHQR'), findsOneWidget);
    expect(find.textContaining('KHR'), findsOneWidget);
    expect(find.text('Finalized'), findsWidgets);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Filter sales'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Branch'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('uses branch name from route args when lookup is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
        ],
        child: const MaterialApp(
          home: SalesDrillDownPage(
            args: SalesDrillDownRouteArgs(
              scope: ReportScopeQuery(
                branchScope: ReportBranchScope.branch,
                branchId: 'branch-mock',
              ),
              branchName: 'Fallback Branch',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fallback Branch'), findsWidgets);
    expect(find.text('Current filter'), findsOneWidget);
  });
}
