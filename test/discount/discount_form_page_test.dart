import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/ui/view/discount_rule_form/discount_rule_form_page.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_support_providers.dart';

import '../test_utils/pump_app.dart';

AuthSession _session(String role) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: role,
      tenantId: 'tenant-001',
    ),
    memberships: [
      TenantMembership(
        tenantId: 'tenant-001',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [],
      ),
    ],
    activeTenantId: 'tenant-001',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

void main() {
  testWidgets('discount form is read-only for manager role', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: DiscountRuleFormPage()),
      overrides: [
        initialAuthSessionProvider.overrideWithValue(_session('manager')),
        discountRepositoryProvider.overrideWithValue(MockDiscountRepository()),
        discountTenantBranchesProvider.overrideWith(
          (ref) async => const [
            BranchListItem(
              branchId: 'branch-001',
              tenantId: 'tenant-001',
              branchName: 'Main Branch',
              status: 'ACTIVE',
            ),
          ],
        ),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Create discount'), findsNothing);
    expect(find.text('Save'), findsNothing);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
