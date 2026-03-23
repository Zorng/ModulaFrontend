import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/app.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_support_providers.dart';
import 'package:modular_pos/features/menu/data/mock_menu_repository.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_unread_count_controller.dart';

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

class _StaticUnreadCountController
    extends OperationalNotificationUnreadCountController {
  @override
  Future<int> build() async => 0;
}

AuthSession _session(String role) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: role,
      tenantId: 'tenant-001',
      branches: const [
        UserBranch(
          id: 'assignment-001',
          name: 'Main Branch',
          role: 'cashier',
          active: true,
          branchId: 'branch-001',
        ),
      ],
    ),
    memberships: [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-001',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [
          UserBranch(
            id: 'assignment-001',
            name: 'Main Branch',
            role: 'cashier',
            active: true,
            branchId: 'branch-001',
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

List<BranchListItem> _branches() {
  return const [
    BranchListItem(
      branchId: 'branch-001',
      tenantId: 'tenant-001',
      branchName: 'Main Branch',
      status: 'ACTIVE',
    ),
  ];
}

Widget _routerHarness(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1800, 1200);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

ProviderContainer _createContainer(String role) {
  return ProviderContainer(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_session(role)),
      ),
      activeBranchContextIdProvider.overrideWithValue('branch-001'),
      discountRepositoryProvider.overrideWithValue(MockDiscountRepository()),
      discountTenantBranchesProvider.overrideWith((ref) async => _branches()),
      menuRepositoryProvider.overrideWithValue(const MockMenuRepository()),
      operationalNotificationUnreadCountControllerProvider.overrideWith(
        () => _StaticUnreadCountController(),
      ),
    ],
  );
}

Future<void> _pumpRoute(
  WidgetTester tester,
  ProviderContainer container,
  String path,
) async {
  container.read(appRouterProvider).go(path);
  await tester.pumpWidget(_routerHarness(container));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('admin can open discount form route', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = _createContainer('admin');
    addTearDown(container.dispose);

    await _pumpRoute(tester, container, AppRoute.discountRuleForm.path);

    expect(find.text('Add discount'), findsOneWidget);
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('manager can open discount list read-only', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = _createContainer('manager');
    addTearDown(container.dispose);

    await _pumpRoute(tester, container, AppRoute.discount.path);

    expect(
      find.text(
        'Discount rules are assigned to one branch and applied only in that branch. Managers and cashiers can view rules but cannot change them.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add discount'), findsNothing);
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('cashier can open discount detail read-only', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = _createContainer('cashier');
    addTearDown(container.dispose);

    await _pumpRoute(
      tester,
      container,
      AppRoute.discountRuleDetail.path.replaceFirst(':ruleId', 'disc-002'),
    );

    expect(
      find.text(
        'This view is read-only for manager and cashier roles. Admin or owner can edit or change lifecycle state.',
      ),
      findsOneWidget,
    );
    expect(find.text('Edit rule'), findsNothing);
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('cashier can open branch discount route', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = _createContainer('cashier');
    addTearDown(container.dispose);

    await _pumpRoute(tester, container, AppRoute.branchDiscount.path);

    expect(find.text('Morning Coffee 10%'), findsOneWidget);
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('cashier cannot open discount form route', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = _createContainer('cashier');
    addTearDown(container.dispose);

    await _pumpRoute(tester, container, AppRoute.discountRuleForm.path);

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('Add discount'), findsNothing);
  });
}
