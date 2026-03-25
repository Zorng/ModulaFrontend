import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item_detail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_unread_count_controller.dart';
import 'package:modular_pos/features/discount/ui/view/discount/discount_page.dart';
import 'package:modular_pos/features/discount/ui/view/discount_rule_detail/discount_rule_detail_page.dart';
import 'package:modular_pos/features/discount/ui/view/discount_rule_form/discount_rule_form_page.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_support_providers.dart';

import '../test_utils/pump_app.dart';

class _StaticUnreadCountController
    extends OperationalNotificationUnreadCountController {
  @override
  Future<int> build() async => 0;
}

class _BranchMenuRepository extends MenuRepository {
  const _BranchMenuRepository();

  @override
  Future<MenuDataBundle> fetchMenuData({
    MenuReadLane readLane = MenuReadLane.management,
    String status = 'active',
    String? categoryId,
    String? search,
    int? limit,
    int? offset,
    String? branchIdFilter,
  }) async {
    return MenuDataBundle(
      items: switch (status.toLowerCase()) {
        'archived' => const <MenuItem>[
          MenuItem(
            id: 'menu-coffee-002',
            name: 'Iced Coffee',
            categoryId: 'cat-1',
            price: 3,
            status: 'ARCHIVED',
            visibleBranchIds: <String>['branch-001'],
          ),
        ],
        _ => const <MenuItem>[
          MenuItem(
            id: 'menu-coffee-001',
            name: 'House Coffee',
            categoryId: 'cat-1',
            price: 2.5,
            visibleBranchIds: <String>['branch-001'],
          ),
        ],
      },
      categories: [],
      modifierGroups: [],
      branches: [],
    );
  }

  @override
  Future<List<MenuCategory>> fetchCategoriesOnly({String? status}) async =>
      throw UnimplementedError();

  @override
  Future<MenuItemDetail> fetchMenuItemDetail(String menuItemId) async =>
      throw UnimplementedError();

  @override
  Future<List<MenuModifierOptionEffect>> fetchMenuItemModifierOptionEffects(
    String menuItemId,
  ) async => throw UnimplementedError();

  @override
  Future<(MenuItem, List<ModifierGroup>)> fetchItemWithModifiers(
    String menuItemId, {
    bool retrying = false,
  }) async => throw UnimplementedError();

  @override
  Future<List<MenuComponent>> fetchMenuItemComposition(
    String menuItemId,
  ) async => throw UnimplementedError();

  @override
  Future<void> upsertMenuItemComposition({
    required String menuItemId,
    required List baseComponents,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertMenuItemModifierOptionEffects({
    required String menuItemId,
    required List<MenuModifierOptionEffect> effects,
  }) async => throw UnimplementedError();

  @override
  Future<MenuCompositionEvaluate> evaluateMenuItemComposition({
    required String menuItemId,
    required List<String> selectedModifierOptionIds,
  }) async => throw UnimplementedError();

  @override
  Future<List<ModifierGroup>> fetchModifierGroupsOnly({String? status}) async =>
      throw UnimplementedError();

  @override
  Future<MenuCategory> createCategory(MenuCategory category) async =>
      throw UnimplementedError();

  @override
  Future<MenuCategory> updateCategory(MenuCategory category) async =>
      throw UnimplementedError();

  @override
  Future<void> archiveCategory(String categoryId) async =>
      throw UnimplementedError();

  @override
  Future<void> restoreCategory(String categoryId) async =>
      throw UnimplementedError();

  @override
  Future<ModifierGroup> createModifierGroup(ModifierGroup group) async =>
      throw UnimplementedError();

  @override
  Future<ModifierGroup> updateModifierGroup(
    ModifierGroup group, {
    ModifierGroup? previous,
  }) async => throw UnimplementedError();

  @override
  Future<void> archiveModifierGroup(String groupId) async =>
      throw UnimplementedError();

  @override
  Future<void> restoreModifierGroup(String groupId) async =>
      throw UnimplementedError();

  @override
  Future<MenuItem> createMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async => throw UnimplementedError();

  @override
  Future<MenuItem> updateMenuItem(
    MenuItem item, {
    String? imagePath,
    List<int>? imageBytes,
    MenuItem? previous,
  }) async => throw UnimplementedError();

  @override
  Future<void> archiveMenuItem(String menuItemId) async =>
      throw UnimplementedError();

  @override
  Future<void> restoreMenuItem(String menuItemId) async =>
      throw UnimplementedError();

  @override
  Future<void> setMenuItemVisibility({
    required String menuItemId,
    required List<String> visibleBranchIds,
  }) async => throw UnimplementedError();

  @override
  Future<void> setMenuItemAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) async => throw UnimplementedError();

  @override
  Future<void> setMenuItemPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) async => throw UnimplementedError();
}

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
  tester.view.physicalSize = const Size(1800, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpApp(tester, child, overrides: overrides.cast());
}

Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget child, {
  required List overrides,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(430, 932);
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
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          menuRepositoryProvider.overrideWithValue(
            const _BranchMenuRepository(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Add discount'), findsOneWidget);
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
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Discount rules are assigned to one branch and applied only in that branch. Managers and cashiers can view rules but cannot change them.',
        ),
        findsOneWidget,
      );
      expect(find.text('Add discount'), findsNothing);
    });

    testWidgets('branch discount view shows only active current-branch rules', (
      tester,
    ) async {
      await _pumpWide(
        tester,
        const DiscountPage(branchActiveOnly: true),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('manager')),
          activeBranchContextIdProvider.overrideWithValue('branch-001'),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          menuRepositoryProvider.overrideWithValue(
            const _BranchMenuRepository(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Morning Coffee 10%'), findsOneWidget);
      expect(find.text('Branch Opening Promo'), findsNothing);
      expect(find.text('Add discount'), findsNothing);
      expect(
        find.text(
          'Managers and cashiers can view discount rules, but only admin or owner can create or edit them.',
        ),
        findsNothing,
      );
      expect(find.text('All statuses'), findsNothing);
      expect(find.text('All scopes'), findsNothing);
      expect(find.text('View details'), findsNothing);
      expect(find.text('See more'), findsOneWidget);
      expect(find.text('House Coffee'), findsNothing);
      expect(find.text('Iced Coffee'), findsNothing);
      expect(find.text('menu-coffee-001'), findsNothing);
      expect(find.text('menu-coffee-002'), findsNothing);

      await tester.tap(find.text('See more'));
      await tester.pumpAndSettle();

      expect(find.text('Discounted Items'), findsOneWidget);
      expect(find.text('House Coffee'), findsOneWidget);
      expect(find.text('Iced Coffee'), findsOneWidget);
    });

    testWidgets('branch active discount view stays read-only for owner', (
      tester,
    ) async {
      await _pumpWide(
        tester,
        const DiscountPage(branchActiveOnly: true),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('owner')),
          activeBranchContextIdProvider.overrideWithValue('branch-001'),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          menuRepositoryProvider.overrideWithValue(
            const _BranchMenuRepository(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Add discount'), findsNothing);
      expect(find.text('View details'), findsNothing);
      expect(find.text('Edit rule'), findsNothing);
      expect(
        find.text(
          'This branch workspace is a read-only operator board. It lists active discount rules for the selected branch without opening rule detail or edit flows.',
        ),
        findsOneWidget,
      );
      expect(find.text('See more'), findsOneWidget);
    });

    testWidgets('branch active discount uses bottom sheet on narrow screens', (
      tester,
    ) async {
      await _pumpNarrow(
        tester,
        const DiscountPage(branchActiveOnly: true),
        overrides: [
          initialAuthSessionProvider.overrideWithValue(_session('cashier')),
          activeBranchContextIdProvider.overrideWithValue('branch-001'),
          discountRepositoryProvider.overrideWithValue(
            MockDiscountRepository(),
          ),
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          menuRepositoryProvider.overrideWithValue(
            const _BranchMenuRepository(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('See more'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Discounted Items'), findsOneWidget);
      expect(find.text('House Coffee'), findsOneWidget);
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
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit rule'), findsOneWidget);
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
          discountTenantBranchesProvider.overrideWith(
            (ref) async => _branches(),
          ),
          operationalNotificationUnreadCountControllerProvider.overrideWith(
            () => _StaticUnreadCountController(),
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
