import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_detail/sale_detail_page.dart';

class _MockSaleRepository extends Mock implements SaleCheckoutRepository {}

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession? _session;

  @override
  LoginState build() => LoginState(session: _session);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SaleRequestVoidCommand(
        saleId: 'sale-1',
        reason: 'Reason',
        clientOpId: 'client-op',
      ),
    );
    registerFallbackValue(
      const SaleApproveVoidCommand(saleId: 'sale-1', clientOpId: 'client-op'),
    );
    registerFallbackValue(
      const SaleRejectVoidCommand(saleId: 'sale-1', clientOpId: 'client-op'),
    );
  });

  testWidgets('SaleDetailPage shows loading while detail is in flight', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    final completer = Completer<SaleDetailReadDto>();
    when(
      () => repo.getSaleDetail(saleId: 'sale-1'),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SaleDetailPage shows empty-state copy for missing sale id', (
    tester,
  ) async {
    final repo = _MockSaleRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: '   ')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale ID is required.'), findsOneWidget);
    verifyNever(() => repo.getSaleDetail(saleId: any(named: 'saleId')));
  });

  testWidgets('SaleDetailPage shows retry state on load failure', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenThrow(
      const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.unknownError,
        message: 'Backend broke.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load sale.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('SaleDetailPage renders sale overview and void request', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    when(
      () => repo.getSaleDetail(saleId: 'sale-1'),
    ).thenAnswer((_) async => _saleDetail());
    when(
      () => repo.getSaleVoidRequest(saleId: 'sale-1'),
    ).thenAnswer((_) async => _voidRequest());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sale Detail'), findsOneWidget);
    expect(find.text('Sale Record'), findsOneWidget);
    expect(find.text('Receipt No.'), findsOneWidget);
    expect(find.text('RCP-20260325-0001'), findsOneWidget);
    expect(find.text('Void Pending'), findsNWidgets(2));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Order ID'), findsNothing);
    await tester.scrollUntilVisible(find.text('Void Request'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Void Request'), findsOneWidget);
    expect(find.text('Wrong item prepared'), findsOneWidget);
    expect(find.text('1 × Iced Latte'), findsOneWidget);
    expect(find.text('Less ice, Oat milk'), findsOneWidget);
  });

  testWidgets('SaleDetailPage lets cashier request void on finalized sale', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    var saleReadCount = 0;
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenAnswer((_) async {
      saleReadCount += 1;
      return saleReadCount == 1
          ? _finalizedSaleDetail()
          : _finalizedSaleDetail(status: 'VOID_PENDING');
    });
    when(() => repo.getSaleVoidRequest(saleId: 'sale-1')).thenAnswer((_) async {
      return saleReadCount == 1 ? null : _voidRequest();
    });
    when(
      () => repo.requestSaleVoid(any()),
    ).thenAnswer((_) async => _voidRequest());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('cashier')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Request void'), 200);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Request void'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Request void'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Wrong item prepared');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.requestSaleVoid(captureAny())).captured.single
            as SaleRequestVoidCommand;
    expect(captured.saleId, 'sale-1');
    expect(captured.reason, 'Wrong item prepared');

    await tester.scrollUntilVisible(find.text('Void Request'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Void Request'), findsOneWidget);
    expect(find.text('Wrong item prepared'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Request void'), findsNothing);
    verify(() => repo.getSaleDetail(saleId: 'sale-1')).called(2);
    verify(() => repo.getSaleVoidRequest(saleId: 'sale-1')).called(2);
  });

  testWidgets('SaleDetailPage lets admin request void on finalized sale', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    var saleReadCount = 0;
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenAnswer((_) async {
      saleReadCount += 1;
      return saleReadCount == 1
          ? _finalizedSaleDetail()
          : _finalizedSaleDetail(status: 'VOID_PENDING');
    });
    when(() => repo.getSaleVoidRequest(saleId: 'sale-1')).thenAnswer((_) async {
      return saleReadCount == 1 ? null : _voidRequest();
    });
    when(
      () => repo.requestSaleVoid(any()),
    ).thenAnswer((_) async => _voidRequest());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('admin')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Request void'), 200);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Request void'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Request void'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Solo admin review');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.requestSaleVoid(captureAny())).captured.single
            as SaleRequestVoidCommand;
    expect(captured.saleId, 'sale-1');
    expect(captured.reason, 'Solo admin review');
  });

  testWidgets('SaleDetailPage lets admin approve a pending void request', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    var saleReadCount = 0;
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenAnswer((_) async {
      saleReadCount += 1;
      return saleReadCount == 1 ? _saleDetail() : _approvedSaleDetail();
    });
    when(() => repo.getSaleVoidRequest(saleId: 'sale-1')).thenAnswer((_) async {
      return saleReadCount == 1 ? _voidRequest() : _approvedVoidRequest();
    });
    when(
      () => repo.approveSaleVoid(any()),
    ).thenAnswer((_) async => _approvedVoidRequest());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('admin')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Approve'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Approved by manager');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Approve'),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.approveSaleVoid(captureAny())).captured.single
            as SaleApproveVoidCommand;
    expect(captured.saleId, 'sale-1');
    expect(captured.note, 'Approved by manager');

    await tester.scrollUntilVisible(find.text('Void Request'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Approved by manager'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Approve'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsNothing);
    verify(() => repo.getSaleDetail(saleId: 'sale-1')).called(2);
    verify(() => repo.getSaleVoidRequest(saleId: 'sale-1')).called(2);
  });

  testWidgets('SaleDetailPage lets admin reject a pending void request', (
    tester,
  ) async {
    final repo = _MockSaleRepository();
    var saleReadCount = 0;
    when(() => repo.getSaleDetail(saleId: 'sale-1')).thenAnswer((_) async {
      saleReadCount += 1;
      return saleReadCount == 1
          ? _saleDetail()
          : _finalizedSaleDetail(status: 'FINALIZED');
    });
    when(() => repo.getSaleVoidRequest(saleId: 'sale-1')).thenAnswer((_) async {
      return saleReadCount == 1 ? _voidRequest() : _rejectedVoidRequest();
    });
    when(
      () => repo.rejectSaleVoid(any()),
    ).thenAnswer((_) async => _rejectedVoidRequest());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          loginControllerProvider.overrideWith(
            () => _StaticLoginController(_sessionForRole('admin')),
          ),
        ],
        child: const MaterialApp(home: SaleDetailPage(saleId: 'sale-1')),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Reject'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Keep sale record');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Reject'),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.rejectSaleVoid(captureAny())).captured.single
            as SaleRejectVoidCommand;
    expect(captured.saleId, 'sale-1');
    expect(captured.note, 'Keep sale record');

    await tester.scrollUntilVisible(find.text('Void Request'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Keep sale record'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Approve'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsNothing);
    verify(() => repo.getSaleDetail(saleId: 'sale-1')).called(2);
    verify(() => repo.getSaleVoidRequest(saleId: 'sale-1')).called(2);
  });
}

AuthSession _sessionForRole(String role) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Test User',
      role: role,
      tenantId: 'tenant-1',
    ),
    memberships: [
      TenantMembership(
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'token',
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.utc(2026, 4, 1),
    refreshTokenExpiresAt: DateTime.utc(2026, 5, 1),
  );
}

SaleDetailReadDto _saleDetail() {
  return SaleDetailReadDto(
    saleId: 'sale-1',
    orderId: 'order-1',
    receiptNumber: 'RCP-20260325-0001',
    status: 'VOID_PENDING',
    saleType: 'TAKEAWAY',
    paymentMethod: 'KHQR',
    tenderCurrency: 'USD',
    fulfillmentStatus: 'READY',
    subtotalUsdExact: 8,
    subtotalKhrExact: 32800,
    discountUsdExact: 0,
    discountKhrExact: 0,
    taxUsdExact: 0,
    taxKhrExact: 0,
    totalUsdExact: 8,
    totalKhrExact: 32800,
    cashReceivedUsd: null,
    cashReceivedKhr: null,
    changeGivenUsd: 0,
    changeGivenKhr: null,
    createdAt: DateTime(2026, 3, 25, 10),
    updatedAt: DateTime(2026, 3, 25, 10, 5),
    finalizedAt: DateTime(2026, 3, 25, 10, 3),
    voidedAt: null,
    voidReason: null,
    lines: const [
      SaleDetailLineDto(
        lineId: 'line-1',
        menuItemId: 'item-1',
        menuItemName: 'Iced Latte',
        quantity: 1,
        modifierLabels: ['Less ice', 'Oat milk'],
      ),
    ],
  );
}

SaleDetailReadDto _finalizedSaleDetail({String status = 'FINALIZED'}) {
  return SaleDetailReadDto(
    saleId: 'sale-1',
    orderId: 'order-1',
    receiptNumber: 'RCP-20260325-0001',
    status: status,
    saleType: 'TAKEAWAY',
    paymentMethod: 'KHQR',
    tenderCurrency: 'USD',
    fulfillmentStatus: 'READY',
    subtotalUsdExact: 8,
    subtotalKhrExact: 32800,
    discountUsdExact: 0,
    discountKhrExact: 0,
    taxUsdExact: 0,
    taxKhrExact: 0,
    totalUsdExact: 8,
    totalKhrExact: 32800,
    cashReceivedUsd: null,
    cashReceivedKhr: null,
    changeGivenUsd: 0,
    changeGivenKhr: null,
    createdAt: DateTime(2026, 3, 25, 10),
    updatedAt: DateTime(2026, 3, 25, 10, 5),
    finalizedAt: DateTime(2026, 3, 25, 10, 3),
    voidedAt: null,
    voidReason: null,
    lines: const [
      SaleDetailLineDto(
        lineId: 'line-1',
        menuItemId: 'item-1',
        menuItemName: 'Iced Latte',
        quantity: 1,
        modifierLabels: ['Less ice', 'Oat milk'],
      ),
    ],
  );
}

SaleVoidRequestReadDto _voidRequest() {
  return SaleVoidRequestReadDto(
    requestId: 'vr-1',
    saleId: 'sale-1',
    status: 'PENDING',
    reason: 'Wrong item prepared',
    requestedAt: DateTime(2026, 3, 25, 10, 6),
    reviewNote: null,
    reviewedAt: null,
    requestedByAccountId: 'staff-1',
    reviewedByAccountId: null,
  );
}

SaleVoidRequestReadDto _approvedVoidRequest() {
  return SaleVoidRequestReadDto(
    requestId: 'vr-1',
    saleId: 'sale-1',
    status: 'APPROVED',
    reason: 'Wrong item prepared',
    requestedAt: DateTime(2026, 3, 25, 10, 6),
    reviewNote: 'Approved by manager',
    reviewedAt: DateTime(2026, 3, 25, 10, 8),
    requestedByAccountId: 'staff-1',
    reviewedByAccountId: 'admin-1',
  );
}

SaleVoidRequestReadDto _rejectedVoidRequest() {
  return SaleVoidRequestReadDto(
    requestId: 'vr-1',
    saleId: 'sale-1',
    status: 'REJECTED',
    reason: 'Wrong item prepared',
    requestedAt: DateTime(2026, 3, 25, 10, 6),
    reviewNote: 'Keep sale record',
    reviewedAt: DateTime(2026, 3, 25, 10, 8),
    requestedByAccountId: 'staff-1',
    reviewedByAccountId: 'admin-1',
  );
}

SaleDetailReadDto _approvedSaleDetail() {
  return SaleDetailReadDto(
    saleId: 'sale-1',
    orderId: 'order-1',
    receiptNumber: 'RCP-20260325-0001',
    status: 'VOIDED',
    saleType: 'TAKEAWAY',
    paymentMethod: 'KHQR',
    tenderCurrency: 'USD',
    fulfillmentStatus: 'CANCELLED',
    subtotalUsdExact: 8,
    subtotalKhrExact: 32800,
    discountUsdExact: 0,
    discountKhrExact: 0,
    taxUsdExact: 0,
    taxKhrExact: 0,
    totalUsdExact: 8,
    totalKhrExact: 32800,
    cashReceivedUsd: null,
    cashReceivedKhr: null,
    changeGivenUsd: 0,
    changeGivenKhr: null,
    createdAt: DateTime(2026, 3, 25, 10),
    updatedAt: DateTime(2026, 3, 25, 10, 8),
    finalizedAt: DateTime(2026, 3, 25, 10, 3),
    voidedAt: DateTime(2026, 3, 25, 10, 8),
    voidReason: 'Wrong item prepared',
    lines: const [
      SaleDetailLineDto(
        lineId: 'line-1',
        menuItemId: 'item-1',
        menuItemName: 'Iced Latte',
        quantity: 1,
        modifierLabels: ['Less ice', 'Oat milk'],
      ),
    ],
  );
}
