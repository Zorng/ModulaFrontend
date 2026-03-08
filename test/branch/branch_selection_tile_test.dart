import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/branch_selection_tile.dart';

void main() {
  testWidgets('BranchSelectionTile triggers manage callback from kebab menu', (
    tester,
  ) async {
    var managed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchSelectionTile(
            branch: const BranchListItem(
              branchId: 'branch-1',
              tenantId: 'tenant-1',
              branchName: 'Olympic',
              status: 'ACTIVE',
            ),
            enabled: true,
            onTap: () {},
            onManage: () => managed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Branch actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage branch'));
    await tester.pumpAndSettle();

    expect(managed, isTrue);
  });
}
