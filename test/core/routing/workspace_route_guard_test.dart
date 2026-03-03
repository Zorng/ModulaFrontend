import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';

void main() {
  test('isPathInGroup matches exact and nested paths', () {
    expect(isPathInGroup('/sale', '/sale'), isTrue);
    expect(isPathInGroup('/sale/cart', '/sale'), isTrue);
    expect(isPathInGroup('/cash/session', '/sale'), isFalse);
  });

  test('guard returns branch-selection redirect when branch id is missing', () {
    final redirect = guardBranchWorkspaceAccess(
      workspaceContext: WorkspaceContext.branchManagement(activeBranchId: ''),
      activeBranchId: null,
    );

    expect(redirect, '/select-branch?reason=branch_context_required');
  });

  test('guard blocks non-branch workspace access for branch-scoped route', () {
    final redirect = guardBranchWorkspaceAccess(
      workspaceContext: WorkspaceContext.globalManagement,
      activeBranchId: null,
    );

    expect(redirect, '/404');
  });

  test('guard allows branch workspace access when branch id exists', () {
    final redirect = guardBranchWorkspaceAccess(
      workspaceContext: WorkspaceContext.branchPos(activeBranchId: 'branch-a'),
      activeBranchId: 'branch-a',
    );

    expect(redirect, isNull);
  });
}
