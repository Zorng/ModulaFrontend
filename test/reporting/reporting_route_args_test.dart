import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';

void main() {
  test('sales drill-down route args round-trip through query parameters', () {
    const args = SalesDrillDownRouteArgs(
      scope: ReportScopeQuery(
        window: ReportTimeWindow.custom,
        from: '2026-03-01',
        to: '2026-03-24',
        branchScope: ReportBranchScope.branch,
        branchId: 'branch-1',
      ),
      branchName: 'Main Branch',
    );

    final restored = SalesDrillDownRouteArgs.fromQueryParameters(
      args.toQueryParameters(),
    );

    expect(restored, isNotNull);
    expect(restored!.scope.window, ReportTimeWindow.custom);
    expect(restored.scope.from, '2026-03-01');
    expect(restored.scope.to, '2026-03-24');
    expect(restored.scope.branchScope, ReportBranchScope.branch);
    expect(restored.scope.branchId, 'branch-1');
    expect(restored.branchName, 'Main Branch');
  });

  test('restock drill-down route args round-trip through query parameters', () {
    const args = RestockSpendDrillDownRouteArgs(
      scope: ReportScopeQuery(
        window: ReportTimeWindow.week,
        branchScope: ReportBranchScope.allBranches,
      ),
    );

    final restored = RestockSpendDrillDownRouteArgs.fromQueryParameters(
      args.toQueryParameters(),
    );

    expect(restored, isNotNull);
    expect(restored!.scope.window, ReportTimeWindow.week);
    expect(restored.scope.branchScope, ReportBranchScope.allBranches);
    expect(restored.scope.branchId, isNull);
  });

  test('branch-scoped drill-down args require a branch id', () {
    final restored = SalesDrillDownRouteArgs.fromQueryParameters({
      'window': 'day',
      'branchScope': 'BRANCH',
    });

    expect(restored, isNull);
  });
}
