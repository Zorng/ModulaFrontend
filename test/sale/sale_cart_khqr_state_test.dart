import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/current_session_summary_provider.dart';
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

class _SpyCashSessionViewModel extends CashSessionViewModel {
  @override
  CashSessionState build() {
    return const CashSessionState(currentUserAccountId: 'user-1');
  }

  @override
  Future<void> load() async {}
}

class _FixedBranchController extends BranchController {
  _FixedBranchController(this._branchState);

  final BranchState _branchState;

  @override
  BranchState build() => _branchState;
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
        cashSessionViewModelProvider.overrideWith(_SpyCashSessionViewModel.new),
        currentSessionSummaryProvider.overrideWith((ref) async => null),
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
    await notifier.setPaymentMethod('qr');
    final readyState = container.read(saleCartProvider);
    expect(readyState.khqrStatus, SaleKhqrUiStates.readyToGenerate);
    expect(readyState.khqrMd5, isNull);
    expect(readyState.khqrQrPayload, isNull);

    await notifier.generateKhqrAttempt();

    final afterGenerate = container.read(saleCartProvider);
    expect(afterGenerate.saleId, isNull);
    expect(afterGenerate.khqrStatus, SaleKhqrUiStates.waitingForPayment);
    expect(afterGenerate.khqrMd5, isNotNull);
    expect(afterGenerate.khqrQrPayload, isNotNull);
    expect(afterGenerate.khqrPayloadType, 'EMV_KHQR_STRING');
    expect(afterGenerate.khqrToAccountId, 'mock-bakong-account');
    expect(afterGenerate.khqrAmount, isNotNull);
    expect(afterGenerate.khqrCurrency, 'USD');
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
    expect(confirmed.saleId, isNotEmpty);
    expect(confirmed.khqrStatus, SaleKhqrUiStates.paidConfirmed);
    expect(confirmed.khqrErrorCode, isNull);

    final result = await notifier.checkout();
    expect(result.summary.paymentMethod, 'qr');
    expect(result.summary.saleId, isNotEmpty);
    expect(result.orderId, isNotEmpty);
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
    await notifier.setPaymentMethod('qr');
    final readyState = container.read(saleCartProvider);
    expect(readyState.khqrStatus, SaleKhqrUiStates.readyToGenerate);

    await notifier.generateKhqrAttempt();
    final waitingState = container.read(saleCartProvider);
    expect(waitingState.khqrStatus, SaleKhqrUiStates.waitingForPayment);
    expect(waitingState.lines, hasLength(1));
    final initialAttemptId = waitingState.khqrAttemptId;
    final initialMd5 = waitingState.khqrMd5;

    await notifier.updateQuantity(0, 2);
    final afterChange = container.read(saleCartProvider);
    expect(afterChange.khqrStatus, SaleKhqrUiStates.superseded);
    expect(afterChange.khqrAttemptId, isNull);
    expect(afterChange.khqrMd5, isNull);
    expect(afterChange.khqrQrPayload, isNull);
    expect(afterChange.khqrPayloadType, isNull);
    expect(afterChange.khqrToAccountId, isNull);
    expect(
      afterChange.khqrErrorMessage,
      'Cart changed. Generate a new KHQR code.',
    );
    expect(initialAttemptId, isNotNull);
    expect(initialMd5, isNotNull);
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
      await notifier.setPaymentMethod('qr');
      final readyState = container.read(saleCartProvider);
      expect(readyState.khqrStatus, SaleKhqrUiStates.readyToGenerate);

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
      expect(cancelled.khqrPayloadType, isNull);
      expect(cancelled.khqrToAccountId, isNull);
      expect(cancelled.khqrErrorCode, isNull);
    },
  );

  test(
    'KHQR generation stores missing branch receiver denial deterministically',
    () async {
      final repo = MockSaleRepository();
      repo.configureContext(
        activeBranchId: 'branch-1',
        khqrReceiverConfigured: true,
      );

      final container = createTestContainer(
        overrides: [
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(repo),
          branchControllerProvider.overrideWith(
            () => _FixedBranchController(
              const BranchState(
                branches: [
                  BranchListItem(
                    branchId: 'branch-1',
                    tenantId: 'tenant-1',
                    branchName: 'Branch A',
                    status: 'ACTIVE',
                  ),
                ],
                currentBranchProfile: BranchListItem(
                  branchId: 'branch-1',
                  tenantId: 'tenant-1',
                  branchName: 'Branch A',
                  status: 'ACTIVE',
                ),
              ),
            ),
          ),
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
      await notifier.setPaymentMethod('qr');
      final readyState = container.read(saleCartProvider);
      expect(readyState.khqrStatus, SaleKhqrUiStates.readyToGenerate);

      await expectLater(
        notifier.generateKhqrAttempt(),
        throwsA(isA<SaleCheckoutRepositoryException>()),
      );

      final failedState = container.read(saleCartProvider);
      expect(
        failedState.khqrErrorCode,
        SaleCheckoutReasonCodes.khqrBranchReceiverNotConfigured,
      );
      expect(
        failedState.khqrErrorMessage,
        'Configure a Bakong receiver account for this branch before generating KHQR.',
      );
      expect(failedState.khqrStatus, SaleKhqrUiStates.readyToGenerate);
      expect(failedState.khqrMd5, isNull);
    },
  );
}
