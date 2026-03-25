import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/restock_spend_drill_down_controller.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/restock_spend_summary_controller.dart';
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

    test('updates the drill-down status filter', () async {
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
      await container
          .read(salesDrillDownControllerProvider.notifier)
          .setStatusFilter(SalesDrillDownStatusFilter.finalized);
      final state = container.read(salesDrillDownControllerProvider);

      expect(state.statusFilter, SalesDrillDownStatusFilter.finalized);
    });

    test('updates the drill-down branch scope', () async {
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
      await container
          .read(salesDrillDownControllerProvider.notifier)
          .setBranchScope(ReportBranchScope.allBranches);
      final state = container.read(salesDrillDownControllerProvider);

      expect(state.branchScope, ReportBranchScope.allBranches);
      expect(state.branchId, isNull);
    });

    test('updates the drill-down custom date range', () async {
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
      await container
          .read(salesDrillDownControllerProvider.notifier)
          .setDateRange(
            DateTimeRange(
              start: DateTime(2026, 3, 1),
              end: DateTime(2026, 3, 24),
            ),
          );
      final state = container.read(salesDrillDownControllerProvider);

      expect(state.window, ReportTimeWindow.custom);
      expect(state.scope?.from, '2026-03-01');
      expect(state.scope?.to, '2026-03-24');
    });

    test('applies drill-down filters in a single update', () async {
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
              branches: [
                ReportingBranchOption(id: 'branch-1', name: 'Main'),
                ReportingBranchOption(id: 'branch-2', name: 'North'),
              ],
            ),
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
      await container
          .read(salesDrillDownControllerProvider.notifier)
          .applyFilters(
            window: ReportTimeWindow.custom,
            selectedDateRange: DateTimeRange(
              start: DateTime(2026, 2, 1),
              end: DateTime(2026, 2, 28),
            ),
            branchScope: ReportBranchScope.allBranches,
            branchId: null,
            statusFilter: SalesDrillDownStatusFilter.voided,
          );
      final state = container.read(salesDrillDownControllerProvider);

      expect(state.window, ReportTimeWindow.custom);
      expect(state.scope?.from, '2026-02-01');
      expect(state.scope?.to, '2026-02-28');
      expect(state.branchScope, ReportBranchScope.allBranches);
      expect(state.branchId, isNull);
      expect(state.statusFilter, SalesDrillDownStatusFilter.voided);
    });
  });

  group('RestockSpendSummaryController', () {
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

      final state = container.read(restockSpendSummaryControllerProvider);

      expect(state.branchScope, ReportBranchScope.allBranches);
      expect(state.branchId, isNull);
    });

    test('loads restock spend summary from the reporting repository', () async {
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

      await container
          .read(restockSpendSummaryControllerProvider.notifier)
          .load();
      final state = container.read(restockSpendSummaryControllerProvider);

      expect(state.errorMessage, isNull);
      expect(state.report, isNotNull);
      expect(state.report!.totals.knownCostSpendUsd, 1420.5);
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
          .read(restockSpendSummaryControllerProvider.notifier)
          .setBranchScope(ReportBranchScope.allBranches);
      final state = container.read(restockSpendSummaryControllerProvider);

      expect(state.branchScope, ReportBranchScope.branch);
    });
  });

  group('RestockSpendDrillDownController', () {
    test('loads drill-down records for the selected scope', () async {
      final container = createTestContainer(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
        ],
      );

      await container
          .read(restockSpendDrillDownControllerProvider.notifier)
          .initialize(
            const RestockSpendDrillDownRouteArgs(
              scope: ReportScopeQuery(
                branchScope: ReportBranchScope.branch,
                branchId: 'branch-1',
              ),
            ),
          );
      final state = container.read(restockSpendDrillDownControllerProvider);

      expect(state.errorMessage, isNull);
      expect(state.report, isNotNull);
      expect(state.report!.items, hasLength(1));
      expect(state.report!.items.first.restockBatchId, 'restock-1');
    });

    test('updates the drill-down cost filter', () async {
      final container = createTestContainer(
        overrides: [
          managementReportingRepositoryProvider.overrideWithValue(
            const MockManagementReportingRepository(),
          ),
        ],
      );

      await container
          .read(restockSpendDrillDownControllerProvider.notifier)
          .initialize(
            const RestockSpendDrillDownRouteArgs(
              scope: ReportScopeQuery(
                branchScope: ReportBranchScope.branch,
                branchId: 'branch-1',
              ),
            ),
          );
      await container
          .read(restockSpendDrillDownControllerProvider.notifier)
          .setCostFilter(RestockSpendCostFilter.unknown);
      final state = container.read(restockSpendDrillDownControllerProvider);

      expect(state.costFilter, RestockSpendCostFilter.unknown);
    });
  });
}
