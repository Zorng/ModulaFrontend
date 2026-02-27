import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/widgets/navigation/app_wide_navigation_rail_shell.dart';
import 'package:modular_pos/core/widgets/navigation/workspace_portal_content.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class _FixedWorkspaceContextNotifier extends WorkspaceContextNotifier {
  _FixedWorkspaceContextNotifier(this._context);

  final WorkspaceContext? _context;

  @override
  WorkspaceContext? build() => _context;
}

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

AuthSession _session({required String role}) {
  final branches = const [
    UserBranch(
      id: 'assign-a',
      name: 'Branch A',
      role: 'admin',
      active: true,
      branchId: 'branch-a',
    ),
  ];

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: role,
      tenantId: 'tenant-1',
      branches: branches,
    ),
    memberships: [
      TenantMembership(
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: branches,
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

Widget _portalHarness({
  required AuthSession session,
  required WorkspaceContext context,
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      workspaceContextProvider.overrideWith(
        () => _FixedWorkspaceContextNotifier(context),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: WorkspacePortalContent())),
  );
}

Widget _railHarness({
  required AuthSession session,
  required WorkspaceContext context,
  required String path,
}) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(session),
      ),
      workspaceContextProvider.overrideWith(
        () => _FixedWorkspaceContextNotifier(context),
      ),
    ],
    child: MaterialApp(
      home: AppScaffoldShell(currentPath: path, child: const SizedBox.shrink()),
    ),
  );
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets('portal shows global workspace cards for admin', (tester) async {
    await tester.pumpWidget(
      _portalHarness(
        session: _session(role: 'admin'),
        context: WorkspaceContext.globalManagement,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Policy'), findsNothing);
  });

  testWidgets('portal shows POS cards for cashier', (tester) async {
    await tester.pumpWidget(
      _portalHarness(
        session: _session(role: 'cashier'),
        context: WorkspaceContext.branchPos(activeBranchId: 'branch-a'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sale'), findsOneWidget);
    expect(find.text('Cash Sessions'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Policy'), findsNothing);
  });

  testWidgets('wide rail shows branch-management destinations', (tester) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(
      _railHarness(
        session: _session(role: 'admin'),
        context: WorkspaceContext.branchManagement(activeBranchId: 'branch-a'),
        path: '/policy',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Policy'), findsOneWidget);
    expect(find.text('Branch Subscription'), findsOneWidget);
    expect(find.text('POS Mode'), findsOneWidget);
    expect(find.text('Branches'), findsNothing);

    final policyTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Policy'),
    );
    expect(policyTile.selected, isTrue);
  });

  testWidgets('wide rail keeps selection correct after mode switch', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final session = _session(role: 'admin');

    await tester.pumpWidget(
      _railHarness(
        session: session,
        context: WorkspaceContext.branchManagement(activeBranchId: 'branch-a'),
        path: '/policy',
      ),
    );
    await tester.pumpAndSettle();

    final managementTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Policy'),
    );
    expect(managementTile.selected, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      _railHarness(
        session: session,
        context: WorkspaceContext.branchPos(activeBranchId: 'branch-a'),
        path: '/sale',
      ),
    );
    await tester.pumpAndSettle();

    final posTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Sale'),
    );
    expect(posTile.selected, isTrue);
    expect(find.text('Policy'), findsNothing);
  });
}
