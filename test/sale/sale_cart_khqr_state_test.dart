import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('KHQR checkout requires paid confirmation before finalize', () async {
    final repo = MockSaleRepository();
    repo.configureContext(activeBranchId: 'branch-1');

    final container = createTestContainer(
      overrides: [
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        saleRepositoryProvider.overrideWithValue(repo),
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
      name: 'Milk Tea',
      categoryId: 'tea',
      price: 1.5,
    );
    const selection = SaleItemSelectionResult(
      item: item,
      quantity: 1,
      selectedOptionIds: {},
      selectedOptions: {},
      addonTotalUsd: 0,
      unitPriceUsd: 1.5,
      lineTotalUsd: 1.5,
    );

    await notifier.addSelection(selection);
    notifier.setPaymentMethod('qr');

    await notifier.generateKhqrAttempt();
    final afterGenerate = container.read(saleCartProvider);
    expect(afterGenerate.saleId, isNotEmpty);
    expect(afterGenerate.khqrStatus, SaleKhqrUiStates.waitingForPayment);
    expect(afterGenerate.khqrMd5, isNotNull);
    expect(afterGenerate.khqrErrorCode, isNull);

    await expectLater(
      notifier.checkout(),
      throwsA(
        isA<SaleCheckoutRepositoryException>().having(
          (e) => e.reasonCode,
          'reasonCode',
          SaleCheckoutReasonCodes.khqrNotConfirmed,
        ),
      ),
    );

    await notifier.checkKhqrStatus();
    await notifier.checkKhqrStatus();
    final confirmed = container.read(saleCartProvider);
    expect(confirmed.khqrStatus, SaleKhqrUiStates.paidConfirmed);
    expect(confirmed.khqrErrorCode, isNull);

    final result = await notifier.checkout();
    expect(result.summary.paymentMethod, 'qr');
    expect(result.summary.saleId, isNotEmpty);
    expect(result.receipt?.receiptId, isNotEmpty);
    expect(result.summary.cashReceivedUsd, 0);
    expect(result.summary.changeGivenUsd, 0);
    final afterCheckout = container.read(saleCartProvider);
    expect(afterCheckout.lastReceipt?.receiptId, result.receiptId);
  });

  test('KHQR attempt is superseded when cart changes', () async {
    final repo = MockSaleRepository();
    repo.configureContext(activeBranchId: 'branch-1');

    final container = createTestContainer(
      overrides: [
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
        saleRepositoryProvider.overrideWithValue(repo),
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
      name: 'Milk Tea',
      categoryId: 'tea',
      price: 1.5,
    );
    const selection = SaleItemSelectionResult(
      item: item,
      quantity: 1,
      selectedOptionIds: {},
      selectedOptions: {},
      addonTotalUsd: 0,
      unitPriceUsd: 1.5,
      lineTotalUsd: 1.5,
    );

    await notifier.addSelection(selection);
    notifier.setPaymentMethod('qr');
    await notifier.generateKhqrAttempt();
    final waitingState = container.read(saleCartProvider);
    expect(waitingState.khqrStatus, SaleKhqrUiStates.waitingForPayment);
    expect(waitingState.lines, hasLength(1));

    await notifier.updateQuantity(0, 2);
    final afterChange = container.read(saleCartProvider);
    expect(afterChange.khqrStatus, SaleKhqrUiStates.superseded);
    expect(afterChange.khqrMd5, isNull);
  });

  test(
    'KHQR cancel clears active payload and moves cart to cancelled state',
    () async {
      final repo = MockSaleRepository();
      repo.configureContext(activeBranchId: 'branch-1');

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
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
        name: 'Milk Tea',
        categoryId: 'tea',
        price: 1.5,
      );
      const selection = SaleItemSelectionResult(
        item: item,
        quantity: 1,
        selectedOptionIds: {},
        selectedOptions: {},
        addonTotalUsd: 0,
        unitPriceUsd: 1.5,
        lineTotalUsd: 1.5,
      );

      await notifier.addSelection(selection);
      notifier.setPaymentMethod('qr');
      await notifier.generateKhqrAttempt();

      final waitingState = container.read(saleCartProvider);
      expect(waitingState.khqrStatus, SaleKhqrUiStates.waitingForPayment);
      expect(waitingState.khqrMd5, isNotNull);

      await notifier.cancelKhqrAttempt();

      final cancelled = container.read(saleCartProvider);
      expect(cancelled.khqrStatus, SaleKhqrUiStates.cancelled);
      expect(cancelled.khqrAttemptId, isNull);
      expect(cancelled.khqrMd5, isNull);
      expect(cancelled.khqrQrPayload, isNull);
      expect(cancelled.khqrErrorCode, isNull);
    },
  );
}
