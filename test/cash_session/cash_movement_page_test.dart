import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_movement/cash_movement_page.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

class _StaticCashSessionViewModel extends CashSessionViewModel {
  _StaticCashSessionViewModel(this._state);

  final CashSessionState _state;

  @override
  CashSessionState build() => _state;
}

void main() {
  testWidgets('wide movement page shows context panel and adjustment type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        cashSessionViewModelProvider.overrideWith(
          () => _StaticCashSessionViewModel(
            CashSessionState(
              currentUserAccountId: 'user-1',
              currentUserRole: AuthRole.manager,
              session: CashSession(
                id: 'session-1',
                tenantId: 'tenant-1',
                branchId: 'branch-1',
                openedByAccountId: 'user-1',
                openedByName: 'You',
                openedAt: DateTime.utc(2026, 3, 9, 8),
                status: CashSessionStatuses.open,
                openingFloatUsd: 20,
                openingFloatKhr: 80000,
                closedAt: null,
                closedByAccountId: null,
                closedByName: null,
                closeNote: null,
                totalPaidInUsd: 12,
                totalPaidOutUsd: 4,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(body: CashMovementPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Movement Context'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Adjustment'), findsOneWidget);
    expect(find.text('Session owner'), findsOneWidget);
    expect(find.text('Recent Manual Movements'), findsOneWidget);
  });
}
