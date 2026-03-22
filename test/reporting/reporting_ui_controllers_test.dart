import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/sales_drill_down_controller.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/sales_summary_controller.dart';

import '../test_utils/riverpod_test_utils.dart';

void main() {
  group('SalesSummaryController', () {
    test('defaults admin landing scope to all branches', () {
      final container = createTestContainer(
        overrides: [
          reportingAccessContextProvider.overrideWithValue(
            const ReportingAccessContext(
              role: AuthRole.admin,
              tenantId: 'tenant-1',
              activeBranchId: 'branch-1',
              branches: [ReportingBranchOption(id: 'branch-1', name: 'Main')],
            ),
          ),
        ],
      );

      final state = container.read(salesSummaryControllerProvider);

      expect(state.branchScope, ReportBranchScope.allBranches);
      expect(state.branchId, isNull);
    });

    test('loads sales summary from the reporting repository', () async {
      final container = createTestContainer(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
          reportingAccessContextProvider.overrideWithValue(
            const ReportingAccessContext(
              role: AuthRole.admin,
              tenantId: 'tenant-1',
              activeBranchId: 'branch-1',
              branches: [ReportingBranchOption(id: 'branch-1', name: 'Main')],
            ),
          ),
        ],
      );

      await container.read(salesSummaryControllerProvider.notifier).load();
      final state = container.read(salesSummaryControllerProvider);

      expect(state.errorMessage, isNull);
      expect(state.report, isNotNull);
      expect(state.report!.confirmed.transactionCount, 124);
      expect(state.report!.scope.branchScope, ReportBranchScope.allBranches);
    });

    test('manager scope stays locked to branch reporting', () async {
      final container = createTestContainer(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
          reportingAccessContextProvider.overrideWithValue(
            const ReportingAccessContext(
              role: AuthRole.manager,
              tenantId: 'tenant-1',
              activeBranchId: 'branch-1',
              branches: [ReportingBranchOption(id: 'branch-1', name: 'Main')],
            ),
          ),
        ],
      );

      await container
          .read(salesSummaryControllerProvider.notifier)
          .setBranchScope(ReportBranchScope.allBranches);
      final state = container.read(salesSummaryControllerProvider);

      expect(state.branchScope, ReportBranchScope.branch);
    });

    test(
      'switching from all branches to branch restores a branch selection',
      () async {
        final container = createTestContainer(
          overrides: [
            managementReportingRepositoryProvider.overrideWithValue(
              const MockManagementReportingRepository(),
            ),
            reportingAccessContextProvider.overrideWithValue(
              const ReportingAccessContext(
                role: AuthRole.owner,
                tenantId: 'tenant-1',
                activeBranchId: 'branch-1',
                branches: [
                  ReportingBranchOption(id: 'branch-1', name: 'Main'),
                  ReportingBranchOption(id: 'branch-2', name: 'North'),
                ],
              ),
            ),
          ],
        );

        await container
            .read(salesSummaryControllerProvider.notifier)
            .setBranchScope(ReportBranchScope.branch);
        final state = container.read(salesSummaryControllerProvider);

        expect(state.branchScope, ReportBranchScope.branch);
        expect(state.branchId, 'branch-1');
      },
    );
  });

  group('SalesDrillDownController', () {
    test('loads drill-down records for the selected scope', () async {
      final container = createTestContainer(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
        ],
      );

      await container
          .read(salesDrillDownControllerProvider.notifier)
          .initialize(
            const SalesDrillDownRouteArgs(
              scope: ReportScopeQuery(
                branchScope: ReportBranchScope.branch,
                branchId: 'branch-1',
              ),
            ),
          );
      final state = container.read(salesDrillDownControllerProvider);

      expect(state.errorMessage, isNull);
      expect(state.report, isNotNull);
      expect(state.report!.items, hasLength(1));
      expect(state.report!.items.first.saleId, 'sale-1');
    });
  });
}
