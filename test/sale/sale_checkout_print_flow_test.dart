import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/printing/esc_pos_receipt_formatter.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/core/printing/thermal_printer_state.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockSaleRepository extends Mock implements SaleRepository {}

class _FakeFinalizeCommand extends Fake implements SaleFinalizeSaleCommand {}

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

class _PrefilledSaleCartNotifier extends SaleCartNotifier {
  _PrefilledSaleCartNotifier(this._initialState);

  final SaleCartState _initialState;

  @override
  SaleCartState build() => _initialState;
}

class _RecordingPrinterController extends ThermalPrinterController {
  final List<ThermalReceiptPrintData> printedReceipts =
      <ThermalReceiptPrintData>[];

  @override
  ThermalPrinterState build() {
    return const ThermalPrinterState(status: ThermalPrinterStatus.connected);
  }

  @override
  Future<bool> printReceipt(ThermalReceiptPrintData receipt) async {
    printedReceipts.add(receipt);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeFinalizeCommand());
  });

  test('checkout auto-prints when the thermal printer is connected', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repo = _MockSaleRepository();
    final printerController = _RecordingPrinterController();

    when(() => repo.finalizeSale(any())).thenAnswer(
      (_) async => SaleFinalizeSaleResultDto(
        saleId: 'sale-1',
        status: 'FINALIZED',
        totalUsdExact: 4.95,
        totalKhrExact: 19800,
        idempotentReplay: false,
        receiptId: 'RCP-1001',
        receipt: SaleImmediateReceiptDto(
          receiptId: 'RCP-1001',
          saleId: 'sale-1',
          statusDisplay: 'NORMAL',
          issuedAt: DateTime(2026, 3, 10, 8, 30),
        ),
      ),
    );
    const menuItem = MenuItem(
      id: 'menu-1',
      name: 'Iced Latte',
      categoryId: 'cat-1',
      price: 2.25,
    );

    final container = createTestContainer(
      overrides: [
        saleRepositoryProvider.overrideWithValue(repo),
        saleCartProvider.overrideWith(
          () => _PrefilledSaleCartNotifier(
            const SaleCartState(
              saleId: 'sale-1',
              lines: [
                CartLine(item: menuItem, quantity: 2, selectedOptionIds: {}),
              ],
              cashUsd: 10,
            ),
          ),
        ),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
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
        thermalPrinterControllerProvider.overrideWith(() => printerController),
      ],
    );

    final result = await container.read(saleCartProvider.notifier).checkout();
    await Future<void>.delayed(Duration.zero);

    expect(result.receiptId, 'RCP-1001');
    expect(printerController.printedReceipts, hasLength(1));
    expect(printerController.printedReceipts.single.receiptNumber, 'RCP-1001');
    expect(printerController.printedReceipts.single.items, hasLength(1));
    expect(
      printerController.printedReceipts.single.taxUsd,
      moreOrLessEquals(0.45),
    );
    expect(printerController.printedReceipts.single.changeKhr, 20200);
    expect(
      printerController.printedReceipts.single.items.single.name,
      'Iced Latte',
    );
    verifyNever(() => repo.getReceipt(saleId: any(named: 'saleId')));
  });

  test(
    'checkout print falls back to receipt sale id when finalize sale id is blank',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repo = _MockSaleRepository();
      final printerController = _RecordingPrinterController();

      when(() => repo.finalizeSale(any())).thenAnswer(
        (_) async => SaleFinalizeSaleResultDto(
          saleId: '',
          status: 'FINALIZED',
          totalUsdExact: 4.5,
          totalKhrExact: 18000,
          idempotentReplay: false,
          receiptId: 'sale-2',
          receipt: SaleImmediateReceiptDto(
            receiptId: 'sale-2',
            saleId: 'sale-2',
            statusDisplay: 'NORMAL',
            issuedAt: DateTime(2026, 3, 10, 8, 35),
          ),
        ),
      );
      const menuItem = MenuItem(
        id: 'menu-1',
        name: 'Hot Latte',
        categoryId: 'cat-1',
        price: 4.5,
      );

      final container = createTestContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repo),
          saleCartProvider.overrideWith(
            () => _PrefilledSaleCartNotifier(
              const SaleCartState(
                saleId: 'draft-2',
                lines: [
                  CartLine(item: menuItem, quantity: 1, selectedOptionIds: {}),
                ],
                cashUsd: 10,
              ),
            ),
          ),
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
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
          thermalPrinterControllerProvider.overrideWith(
            () => printerController,
          ),
        ],
      );

      await container.read(saleCartProvider.notifier).checkout();
      await Future<void>.delayed(Duration.zero);

      expect(printerController.printedReceipts, hasLength(1));
      expect(printerController.printedReceipts.single.receiptNumber, 'sale-2');
      expect(
        printerController.printedReceipts.single.items.single.name,
        'Hot Latte',
      );
      expect(container.read(saleCartProvider).lastFinalizedSaleId, 'sale-2');
      verifyNever(() => repo.getReceipt(saleId: any(named: 'saleId')));
    },
  );

  test('manual receipt print uses the receipt API reprint lane', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repo = _MockSaleRepository();
    final printerController = _RecordingPrinterController();

    when(() => repo.getReceipt(saleId: 'sale-3')).thenAnswer(
      (_) async => SaleReceiptDto(
        saleId: 'sale-3',
        receiptNumber: 'RCP-1003',
        paymentMethod: 'cash',
        subtotalUsdExact: 5,
        taxUsdExact: 0.5,
        totalUsdExact: 5.5,
        totalKhrExact: 22000,
        issuedAt: DateTime(2026, 3, 10, 9, 0),
        lines: const [
          SaleReceiptLineDto(
            name: 'API Cappuccino',
            quantity: 1,
            unitPriceUsd: 5,
            lineTotalUsdExact: 5,
          ),
        ],
      ),
    );

    final container = createTestContainer(
      overrides: [
        saleRepositoryProvider.overrideWithValue(repo),
        saleCartProvider.overrideWith(
          () => _PrefilledSaleCartNotifier(
            SaleCartState(
              lastFinalizedSaleId: 'sale-3',
              lastReceiptId: 'RCP-1003',
              lastReceipt: SaleImmediateReceiptDto(
                receiptId: 'RCP-1003',
                saleId: 'sale-3',
                statusDisplay: 'NORMAL',
                issuedAt: DateTime(2026, 3, 10, 9, 0),
              ),
              lastPrintableReceiptData: ThermalReceiptPrintData(
                receiptNumber: 'RCP-1003',
                tenantName: 'Tenant',
                branchName: 'Branch',
                cashierName: 'Cashier',
                paymentMethod: 'cash',
                issuedAt: DateTime(2026, 3, 10, 9),
                subtotalUsd: 4,
                taxUsd: 0,
                totalUsd: 4,
                totalKhr: 16000,
                items: const [
                  ThermalReceiptItemLine(
                    name: 'Local Cart Item',
                    quantity: 1,
                    basePriceUsd: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
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
        thermalPrinterControllerProvider.overrideWith(() => printerController),
      ],
    );

    await container
        .read(saleCartProvider.notifier)
        .printReceipt(saleId: 'sale-3');

    expect(printerController.printedReceipts, hasLength(1));
    expect(
      printerController.printedReceipts.single.items.single.name,
      'API Cappuccino',
    );
    verify(() => repo.getReceipt(saleId: 'sale-3')).called(1);
  });
}
