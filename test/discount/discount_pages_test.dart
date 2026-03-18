import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/ui/view/discount/discount_page.dart';
import 'package:modular_pos/features/discount/ui/view/discount_rule_detail/discount_rule_detail_page.dart';
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

List<BranchListItem> _branches() {
  return const [
    BranchListItem(
      branchId: 'branch-001',
      tenantId: 'tenant-001',
      branchName: 'Main Branch',
      status: 'ACTIVE',
    ),
    BranchListItem(
      branchId: 'branch-002',
      tenantId: 'tenant-001',
      branchName: 'Second Branch',
      status: 'ACTIVE',
    ),
  ];
}

Future<void> _pumpWide(
  WidgetTester tester,
  Widget child, {
  required List overrides,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1440, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(tester, child, overrides: overrides.cast());
}

void main() {
  group('discount pages', () {
    testWidgets('discount list shows add action for admin', (tester) async {
      await _pumpWide(
        tester,
        const DiscountPage(),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('admin')),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Create discount'), findsOneWidget);
      expect(
        find.text(
          'Managers and cashiers can view discount rules, but only admin or owner can create or edit them.',
        ),
        findsNothing,
      );
    });

    testWidgets('discount list shows read-only banner for manager', (
      tester,
    ) async {
      await _pumpWide(
        tester,
        const DiscountPage(),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('manager')),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Managers and cashiers can view discount rules, but only admin or owner can create or edit them.',
        ),
        findsOneWidget,
      );
      expect(find.text('Create discount'), findsNothing);
    });

    testWidgets('discount detail shows edit and lifecycle actions for admin', (
      tester,
    ) async {
      await _pumpWide(
        tester,
        const DiscountRuleDetailPage(ruleId: 'disc-002'),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('admin')),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Activate'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('discount detail is read-only for manager', (tester) async {
      await _pumpWide(
        tester,
        const DiscountRuleDetailPage(ruleId: 'disc-002'),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('manager')),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(
        find.text(
          'This view is read-only for manager and cashier roles. Admin or owner can edit or change lifecycle state.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('discount form create mode shows branch assignment selector', (
      tester,
    ) async {
      await _pumpWide(
        tester,
        const DiscountRuleFormPage(),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('admin')),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Assign branch'), findsOneWidget);
      expect(
        find.text('Each discount rule must be assigned to one branch.'),
        findsOneWidget,
      );
      expect(find.text('Create discount'), findsOneWidget);
    });

    testWidgets('discount form edit mode shows immutable assigned branch', (
      tester,
    ) async {
      await _pumpWide(
        tester,
        const DiscountRuleFormPage(ruleId: 'disc-002'),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('admin')),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Assigned branch'), findsOneWidget);
      expect(
        find.text('Branch assignment is immutable after creation.'),
        findsOneWidget,
      );
      expect(find.text('Assign branch'), findsNothing);
    });
  });
}
