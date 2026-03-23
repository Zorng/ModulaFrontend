import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/data/sale_discount_resolver.dart';
import 'package:modular_pos/features/sale/domain/models/sale_resolved_discount.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _ResolveEligibilityCall {
  const _ResolveEligibilityCall({
    required this.branchId,
    required this.occurredAt,
    required this.lines,
  });

  final String branchId;
  final DateTime occurredAt;
  final List<DiscountEligibilityLineInput> lines;
}

class _ResolvingDiscountRepository extends MockDiscountRepository {
  final List<_ResolveEligibilityCall> calls = <_ResolveEligibilityCall>[];

  @override
  Future<List<DiscountEligibilityRule>> resolveDiscountEligibility({
    required String branchId,
    required DateTime occurredAt,
    required List<DiscountEligibilityLineInput> lines,
  }) async {
    calls.add(
      _ResolveEligibilityCall(
        branchId: branchId,
        occurredAt: occurredAt,
        lines: lines,
      ),
    );
    return const [
      DiscountEligibilityRule(
        ruleId: 'disc-branch-wide',
        percentage: 5,
        scope: 'BRANCH_WIDE',
        itemIds: <String>[],
        stackingPolicy: 'MULTIPLICATIVE',
      ),
      DiscountEligibilityRule(
        ruleId: 'disc-item',
        percentage: 10,
        scope: 'ITEM',
        itemIds: <String>['menu-1'],
        stackingPolicy: 'MULTIPLICATIVE',
      ),
    ];
  }
}

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'cashier',
      tenantId: 'tenant-001',
      branches: const [
        UserBranch(
          id: 'assignment-1',
          name: 'Branch 1',
          role: 'cashier',
          active: true,
          branchId: 'branch-1',
        ),
      ],
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-001',
        tenantName: 'Tenant 1',
        role: 'cashier',
        branches: [
          UserBranch(
            id: 'assignment-1',
            name: 'Branch 1',
            role: 'cashier',
            active: true,
            branchId: 'branch-1',
          ),
        ],
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'SaleDiscountResolver maps resolved rules into sale domain shape',
    () async {
      final repository = _ResolvingDiscountRepository();
      final resolver = SaleDiscountResolver(repository);

      final result = await resolver.resolveForCart(
        branchId: 'branch-1',
        occurredAt: DateTime.utc(2026, 3, 22, 6, 30),
        lines: const [
          SaleDiscountResolveLine(menuItemId: 'menu-1', quantity: 2),
          SaleDiscountResolveLine(menuItemId: 'menu-2', quantity: 1),
        ],
      );

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.branchId, 'branch-1');
      expect(repository.calls.single.lines, hasLength(2));
      expect(result.branchId, 'branch-1');
      expect(result.rules, hasLength(2));
      expect(result.branchWideRules.single.ruleId, 'disc-branch-wide');
      expect(
        result.rulesForMenuItem('menu-1').map((rule) => rule.ruleId),
        containsAll(<String>['disc-branch-wide', 'disc-item']),
      );
    },
  );

  test(
    'SaleCartNotifier stores resolved discounts in cart-local state after addSelection',
    () async {
      final repository = _ResolvingDiscountRepository();
      final container = createTestContainer(
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session()),
          authActiveBranchIdProvider.overrideWithValue('branch-1'),
          discountRepositoryProvider.overrideWithValue(repository),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final notifier = container.read(saleCartProvider.notifier);
      const item = MenuItem(
        id: 'menu-1',
        name: 'Coffee',
        categoryId: 'cat-1',
        price: 2.5,
      );
      const selection = SaleItemSelectionResult(
        item: item,
        quantity: 2,
        selectedOptionIds: {},
        selectedOptions: {},
        addonTotalUsd: 0,
        unitPriceUsd: 2.5,
        lineTotalUsd: 5,
      );

      await notifier.addSelection(selection);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(saleCartProvider);
      expect(repository.calls, isNotEmpty);
      final latestCall = repository.calls.last;
      expect(latestCall.branchId, 'branch-1');
      expect(latestCall.lines, hasLength(1));
      expect(latestCall.lines.single.menuItemId, 'menu-1');
      expect(latestCall.lines.single.quantity, 2);
      expect(state.isResolvingDiscounts, isFalse);
      expect(state.discountResolutionError, isNull);
      expect(state.resolvedDiscounts, isNotNull);
      expect(state.resolvedDiscounts!.branchId, 'branch-1');
      expect(state.resolvedDiscounts!.rules, hasLength(2));
    },
  );
}
