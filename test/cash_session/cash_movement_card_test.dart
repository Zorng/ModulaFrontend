import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/cash_movement_card.dart';

class _StaticCashSessionViewModel extends CashSessionViewModel {
  _StaticCashSessionViewModel(this._state);

  final CashSessionState _state;

  @override
  CashSessionState build() => _state;
}

CashSessionState _openState({
  required AuthRole role,
  String currentUserAccountId = 'user-1',
  String openedByAccountId = 'user-1',
  String openedByName = 'You',
}) {
  return CashSessionState(
    currentUserAccountId: currentUserAccountId,
    currentUserRole: role,
    session: CashSession(
      id: 'session-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      openedByAccountId: openedByAccountId,
      openedByName: openedByName,
      openedAt: DateTime.utc(2026, 3, 9, 8),
      status: CashSessionStatuses.open,
      openingFloatUsd: 20,
      openingFloatKhr: 80000,
      closedAt: null,
      closedByAccountId: null,
      closedByName: null,
      closeNote: null,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    ),
  );
}

void main() {
  testWidgets('cashier sees only paid in and paid out controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        cashSessionViewModelProvider.overrideWith(
          () => _StaticCashSessionViewModel(_openState(role: AuthRole.cashier)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: CashMovementCard(
              isWide: true,
              onAddCashMovement: (_, __, ___, ____) async =>
                  const CashMovementSubmitResult.success(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final paidInButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Paid In'),
    );
    final dollarsButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Dollars'),
    );

    expect(
      paidInButton.style?.backgroundColor?.resolve({}),
      const Color(0xFFED533C),
    );
    expect(paidInButton.style?.foregroundColor?.resolve({}), Colors.white);
    expect(
      dollarsButton.style?.backgroundColor?.resolve({}),
      const Color(0xFFED533C),
    );
    expect(dollarsButton.style?.foregroundColor?.resolve({}), Colors.white);
    expect(find.widgetWithText(OutlinedButton, 'Adjustment'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'KHR'));
    await tester.pumpAndSettle();

    final khrButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'KHR'),
    );
    expect(
      khrButton.style?.backgroundColor?.resolve({}),
      const Color(0xFFED533C),
    );
    expect(khrButton.style?.foregroundColor?.resolve({}), Colors.white);
  });

  testWidgets('manager sees adjustment with direction controls', (
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
            _openState(
              role: AuthRole.manager,
              currentUserAccountId: 'user-2',
              openedByAccountId: 'user-1',
              openedByName: 'John Smith',
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
          home: Scaffold(
            body: CashMovementCard(
              isWide: true,
              onAddCashMovement: (_, __, ___, ____) async =>
                  const CashMovementSubmitResult.success(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Adjustment'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adjustment'));
    await tester.pumpAndSettle();

    expect(find.text('Adjustment Direction'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Increase'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Decrease'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Apply Adjustment'),
      findsOneWidget,
    );
  });

  testWidgets('movement shows focused empty state without an open session', (
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
            const CashSessionState(
              currentUserAccountId: 'user-1',
              currentUserRole: AuthRole.cashier,
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
          home: Scaffold(
            body: CashMovementCard(
              onAddCashMovement: (_, __, ___, ____) async =>
                  const CashMovementSubmitResult.success(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cash Session Required'), findsOneWidget);
    expect(
      find.text(
        'Manual movements are available only while a cash session is open.',
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Open Cash Session'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Paid In'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Dollars'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'movement shows read-only state when no write permissions exist',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          cashSessionViewModelProvider.overrideWith(
            () =>
                _StaticCashSessionViewModel(_openState(role: AuthRole.unknown)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              body: CashMovementCard(
                onAddCashMovement: (_, __, ___, ____) async =>
                    const CashMovementSubmitResult.success(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Read-only movement access'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Paid In'), findsNothing);
    },
  );

  testWidgets('movement clears only after successful submit', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        cashSessionViewModelProvider.overrideWith(
          () => _StaticCashSessionViewModel(_openState(role: AuthRole.cashier)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: CashMovementCard(
              onAddCashMovement: (_, __, ___, ____) async =>
                  const CashMovementSubmitResult.success(),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.enterText(find.byType(TextField).last, 'Drawer top-up');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Cash Movement'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cash movement added successfully'), findsOneWidget);
    expect(find.text('5'), findsNothing);
    expect(find.text('Drawer top-up'), findsNothing);
  });

  testWidgets('movement preserves inputs on failed submit', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        cashSessionViewModelProvider.overrideWith(
          () => _StaticCashSessionViewModel(_openState(role: AuthRole.cashier)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: CashMovementCard(
              onAddCashMovement: (_, __, ___, ____) async =>
                  const CashMovementSubmitResult.failure(
                    'Unable to add cash movement.',
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.enterText(find.byType(TextField).last, 'Drawer top-up');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Cash Movement'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unable to add cash movement.'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Drawer top-up'), findsOneWidget);
  });

  testWidgets('adjustment decrease maps positive input to negative delta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    double? capturedUsdAmount;
    String? capturedType;

    final container = ProviderContainer(
      overrides: [
        cashSessionViewModelProvider.overrideWith(
          () => _StaticCashSessionViewModel(
            _openState(
              role: AuthRole.manager,
              currentUserAccountId: 'user-2',
              openedByAccountId: 'user-1',
              openedByName: 'John Smith',
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
          home: Scaffold(
            body: CashMovementCard(
              onAddCashMovement: (type, usdAmount, _, __) async {
                capturedType = type;
                capturedUsdAmount = usdAmount;
                return const CashMovementSubmitResult.success();
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Adjustment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Decrease'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '5');
    await tester.enterText(find.byType(TextField).last, 'Correction');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply Adjustment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(capturedType, 'Adjustment');
    expect(capturedUsdAmount, -5);
  });
}
