import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_khqr_popup.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

class _KhqrPopupSpyNotifier extends SaleCartNotifier {
  _KhqrPopupSpyNotifier(this._initial);

  final SaleCartState _initial;
  int generateCallCount = 0;
  int cancelCallCount = 0;

  @override
  SaleCartState build() => _initial;

  @override
  Future<void> generateKhqrAttempt() async {
    generateCallCount += 1;
    state = state.copyWith(
      khqrStatus: SaleKhqrUiStates.waitingForPayment,
      khqrAttemptId: 'intent-1',
      khqrMd5: 'md5-1',
      khqrQrPayload: 'KHQR:payload',
      khqrPayloadType: 'EMV_KHQR_STRING',
      khqrToAccountId: 'bakong-001',
      khqrCurrency: 'USD',
    );
  }

  @override
  Future<void> cancelKhqrAttempt() async {
    cancelCallCount += 1;
    state = state.copyWith(
      khqrStatus: SaleKhqrUiStates.cancelled,
      khqrAttemptId: null,
      khqrMd5: null,
      khqrQrPayload: null,
      khqrPayloadType: null,
      khqrToAccountId: null,
      khqrCurrency: null,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPopup(
    WidgetTester tester, {
    required ProviderContainer container,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SaleKhqrPopup(
              readOnly: false,
              grandTotalUsd: 7.5,
              grandTotalKhr: 30000,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpPopupDialog(
    WidgetTester tester, {
    required ProviderContainer container,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      builder: (_) => const SaleKhqrPopup(
                        readOnly: false,
                        grandTotalUsd: 7.5,
                        grandTotalKhr: 30000,
                      ),
                    );
                  },
                  child: const Text('Open popup'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Open popup'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening popup in ready state does not auto-generate or show generate action',
    (tester) async {
      final notifier = _KhqrPopupSpyNotifier(
        const SaleCartState(
          saleId: 'sale-1',
          paymentMethod: 'qr',
          tenderCurrency: 'USD',
          khqrStatus: SaleKhqrUiStates.readyToGenerate,
        ),
      );
      final container = ProviderContainer(
        overrides: [saleCartProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);

      await pumpPopup(tester, container: container);
      await tester.pumpAndSettle();

      expect(notifier.generateCallCount, 0);
      expect(find.text('Ready to generate'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Generate KHQR'), findsNothing);
      expect(
        find.textContaining('Return to the cart to generate'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'receiver missing shows unavailable messaging and hides generate action',
    (tester) async {
      final notifier = _KhqrPopupSpyNotifier(
        const SaleCartState(
          saleId: 'sale-1',
          paymentMethod: 'qr',
          tenderCurrency: 'USD',
          khqrStatus: SaleKhqrUiStates.readyToGenerate,
          khqrErrorCode: 'khqrBranchReceiverNotConfigured',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          saleCartProvider.overrideWith(() => notifier),
          saleKhqrReceiverConfiguredProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      await pumpPopup(tester, container: container);
      await tester.pumpAndSettle();

      expect(find.text('Receiver not configured'), findsOneWidget);
      expect(
        find.textContaining('This branch has no Bakong receiver configured'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Generate KHQR'), findsNothing);
    },
  );

  testWidgets('waiting state only exposes Cancel KHQR', (tester) async {
    final notifier = _KhqrPopupSpyNotifier(
      SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.waitingForPayment,
        khqrQrPayload: 'KHQR:payload',
        khqrPayloadType: 'EMV_KHQR_STRING',
        khqrExpiresAt: DateTime.now().add(const Duration(minutes: 2)),
      ),
    );
    final container = ProviderContainer(
      overrides: [saleCartProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await pumpPopup(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Cancel KHQR'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Close'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Done'), findsNothing);
    expect(find.textContaining('Expires in'), findsOneWidget);
  });

  testWidgets('popup shows receiver name and Bakong logo in QR state', (
    tester,
  ) async {
    final notifier = _KhqrPopupSpyNotifier(
      SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.waitingForPayment,
        khqrQrPayload: 'KHQR:payload',
        khqrPayloadType: 'EMV_KHQR_STRING',
        khqrToAccountId: 'bakong-001',
        khqrReceiverName: 'Modula Cafe',
        khqrExpiresAt: DateTime.now().add(const Duration(minutes: 2)),
      ),
    );
    final container = ProviderContainer(
      overrides: [saleCartProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await pumpPopup(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.text('Modula Cafe'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Cancel KHQR cancels and closes the popup', (tester) async {
    final notifier = _KhqrPopupSpyNotifier(
      const SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.waitingForPayment,
        khqrQrPayload: 'KHQR:payload',
        khqrPayloadType: 'EMV_KHQR_STRING',
      ),
    );
    final container = ProviderContainer(
      overrides: [saleCartProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await pumpPopupDialog(tester, container: container);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel KHQR'));
    await tester.pumpAndSettle();

    expect(notifier.cancelCallCount, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('expired state shows Refresh and Close', (tester) async {
    final notifier = _KhqrPopupSpyNotifier(
      const SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.expired,
      ),
    );
    final container = ProviderContainer(
      overrides: [saleCartProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await pumpPopup(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Refresh'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Close'), findsOneWidget);
  });

  testWidgets(
    'waiting state with past expiresAt shows expired recovery actions',
    (tester) async {
      final notifier = _KhqrPopupSpyNotifier(
        SaleCartState(
          saleId: 'sale-1',
          paymentMethod: 'qr',
          tenderCurrency: 'USD',
          khqrStatus: SaleKhqrUiStates.waitingForPayment,
          khqrQrPayload: 'KHQR:payload',
          khqrPayloadType: 'EMV_KHQR_STRING',
          khqrExpiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
      );
      final container = ProviderContainer(
        overrides: [saleCartProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);

      await pumpPopup(tester, container: container);

      expect(find.widgetWithText(FilledButton, 'Refresh'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Close'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel KHQR'), findsNothing);
    },
  );

  testWidgets('confirmed state shows Done', (tester) async {
    final notifier = _KhqrPopupSpyNotifier(
      const SaleCartState(
        saleId: 'sale-1',
        paymentMethod: 'qr',
        tenderCurrency: 'USD',
        khqrStatus: SaleKhqrUiStates.paidConfirmed,
      ),
    );
    final container = ProviderContainer(
      overrides: [saleCartProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await pumpPopup(tester, container: container);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel KHQR'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Close'), findsNothing);
  });
}
