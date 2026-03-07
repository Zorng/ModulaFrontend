import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';

void main() {
  test('isPathInGroup matches exact and nested paths', () {
    expect(isPathInGroup('/sale', '/sale'), isTrue);
    expect(isPathInGroup('/sale/cart', '/sale'), isTrue);
    expect(isPathInGroup('/cash/session', '/sale'), isFalse);
  });

  test('sanitizeContinuePath accepts only same-app absolute paths', () {
    expect(sanitizeContinuePath('/policy'), '/policy');
    expect(sanitizeContinuePath('/sale/item?id=1'), '/sale/item?id=1');
    expect(sanitizeContinuePath('policy'), isNull);
    expect(sanitizeContinuePath('https://example.com'), isNull);
    expect(sanitizeContinuePath('//example.com'), isNull);
  });

  test('buildBranchSelectionRedirect includes reason and continue path', () {
    final redirect = buildBranchSelectionRedirect(
      reasonCode: branchContextRequiredReasonCode,
      continuePath: '/sale',
    );

    expect(
      redirect,
      '/select-branch?reason=branch_context_required&continue=%2Fsale',
    );
  });

  test('buildBranchesRedirect includes continue path for owner/admin flow', () {
    final redirect = buildBranchesRedirect(
      reasonCode: branchContextRequiredReasonCode,
      continuePath: '/policy',
    );

    expect(
      redirect,
      '/branches?reason=branch_context_required&continue=%2Fpolicy',
    );
  });

  test('role-based branch redirect sends owner/admin to branches', () {
    final redirect = buildBranchScopedRedirectForRole(
      role: AuthRole.admin,
      continuePath: '/cash/session',
      reasonCode: branchContextRequiredReasonCode,
    );

    expect(
      redirect,
      '/branches?reason=branch_context_required&continue=%2Fcash%2Fsession',
    );
  });

  test('role-based branch redirect sends staff to select-branch', () {
    final redirect = buildBranchScopedRedirectForRole(
      role: AuthRole.cashier,
      continuePath: '/sale',
      reasonCode: branchContextRequiredReasonCode,
    );

    expect(
      redirect,
      '/select-branch?reason=branch_context_required&continue=%2Fsale',
    );
  });

  test('readContinuePath ignores unsafe targets', () {
    expect(
      readContinuePath(Uri.parse('/branches?continue=%2Fcash%2Fsession')),
      '/cash/session',
    );
    expect(
      readContinuePath(
        Uri.parse('/branches?continue=https%3A%2F%2Fevil.example'),
      ),
      isNull,
    );
  });
}
