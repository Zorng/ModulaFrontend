import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';

import '../test_utils/riverpod_test_utils.dart';

void main() {
  test('saleAccessBranchIdProvider prefers workspace branch context', () {
    final container = createTestContainer(
      overrides: [
        activeBranchContextIdProvider.overrideWithValue('branch-workspace'),
        authActiveBranchIdProvider.overrideWithValue('branch-auth'),
      ],
    );

    expect(
      container.read(saleAccessBranchIdProvider),
      'branch-workspace',
    );
  });

  test('saleAccessBranchIdProvider falls back to auth branch id', () {
    final container = createTestContainer(
      overrides: [
        activeBranchContextIdProvider.overrideWithValue(null),
        authActiveBranchIdProvider.overrideWithValue('branch-auth'),
      ],
    );

    expect(
      container.read(saleAccessBranchIdProvider),
      'branch-auth',
    );
  });
}
