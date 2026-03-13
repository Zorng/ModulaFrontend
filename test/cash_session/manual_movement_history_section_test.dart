import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/manual_movement_history_section.dart';

void main() {
  testWidgets('manual history filters to manual rows and supports view all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 10);
    final movements = <CashMovement>[
      CashMovement(
        id: 'sale-in',
        sessionId: 'session-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        movementType: CashMovementTypes.saleIn,
        amountUsd: 8,
        amountKhr: 0,
        reason: 'Should be filtered out',
        sourceRefType: 'sale',
        sourceRefId: 'sale-1',
        recordedByAccountId: 'user-1',
        occurredAt: now,
      ),
      for (var index = 0; index < 11; index++)
        CashMovement(
          id: 'manual-$index',
          sessionId: 'session-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          movementType: index.isEven
              ? CashMovementTypes.manualIn
              : CashMovementTypes.adjustment,
          amountUsd: index + 1,
          amountKhr: 0,
          reason: 'manual-$index',
          sourceRefType: 'manual',
          sourceRefId: null,
          recordedByAccountId: 'user-1',
          occurredAt: now.subtract(Duration(minutes: index + 1)),
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ManualMovementHistorySection(movements: movements),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Should be filtered out'), findsNothing);
    expect(find.text('manual-10'), findsNothing);
    expect(find.text('View all (11)'), findsOneWidget);

    await tester.tap(find.text('View all (11)'));
    await tester.pumpAndSettle();

    expect(find.text('manual-10'), findsOneWidget);
    expect(find.text('View less'), findsOneWidget);
  });
}
