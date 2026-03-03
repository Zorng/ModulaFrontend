import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/widgets/navigation/workspace_nav_config.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';

void main() {
  List<String> labels(List<WorkspaceNavSection> sections) {
    return [
      for (final section in sections)
        for (final item in section.items) item.label,
    ];
  }

  test('admin in global workspace sees menu inventory and staff only', () {
    final sections = buildWorkspaceNavSections(
      role: AuthRole.admin,
      workspaceContext: WorkspaceContext.globalManagement,
    );

    expect(labels(sections), ['Menu', 'Inventory', 'Staff']);
  });

  test(
    'admin in branch management sees policy subscription and POS mode entry',
    () {
      final sections = buildWorkspaceNavSections(
        role: AuthRole.admin,
        workspaceContext: WorkspaceContext.branchManagement(
          activeBranchId: 'branch-1',
        ),
      );

      expect(labels(sections), ['Policy', 'Branch Subscription', 'POS Mode']);
    },
  );

  test('admin in branch POS mode sees sale and cash sessions', () {
    final sections = buildWorkspaceNavSections(
      role: AuthRole.admin,
      workspaceContext: WorkspaceContext.branchPos(activeBranchId: 'branch-1'),
    );

    expect(labels(sections), ['Sale', 'Cash Sessions']);
  });

  test('cashier in branch POS mode sees sale cash sessions and attendance', () {
    final sections = buildWorkspaceNavSections(
      role: AuthRole.cashier,
      workspaceContext: WorkspaceContext.branchPos(activeBranchId: 'branch-1'),
    );

    expect(labels(sections), ['Sale', 'Cash Sessions', 'Attendance']);
  });
}
