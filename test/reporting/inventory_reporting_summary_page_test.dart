import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/reporting/data/management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/ui/models/reporting_branch_option.dart';
import 'package:modular_pos/features/reporting/ui/view/inventory_summary/inventory_reporting_summary_page.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';

void main() {
  testWidgets('inventory summary only exposes month and custom date filters', (
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
              activeBranchId: 'branch-1',
              branches: [
                ReportingBranchOption(id: 'branch-1', name: 'Main Branch'),
              ],
            ),
          ),
          branchControllerProvider.overrideWith(
            () => _StaticBranchController(
              const BranchState(
                branches: [
                  BranchListItem(
                    branchId: 'branch-1',
                    tenantId: 'tenant-1',
                    branchName: 'Main Branch',
                    status: 'ACTIVE',
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InventoryReportingSummaryPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dropdownFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownMenu<ReportTimeWindow>,
    );
    final dateDropdown = tester.widget<DropdownMenu<ReportTimeWindow>>(
      dropdownFinder.first,
    );
    final labels = dateDropdown.dropdownMenuEntries
        .map((entry) => entry.label)
        .toList(growable: false);

    expect(labels, ['Month', 'Custom']);
    expect(labels, isNot(contains('Today')));
    expect(labels, isNot(contains('Week')));
  });
}

class _StaticBranchController extends BranchController {
  _StaticBranchController(this._initialState);

  final BranchState _initialState;

  @override
  BranchState build() => _initialState;

  @override
  Future<void> loadInitial() async {}
}
