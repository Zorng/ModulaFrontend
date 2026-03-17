import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail/order_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class _StaticOrdersNotifier extends OrdersNotifier {
  _StaticOrdersNotifier(this._orders);

  final List<Order> _orders;

  @override
  List<Order> build() => _orders;
}

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleAllowPayLater: true,
        saleAllowManualExternalPaymentClaim: true,
      ),
    );
  }
}

class _OnlineConnectivityNotifier extends AppConnectivityStatusController {
  @override
  AppConnectivityStatus build() => AppConnectivityStatus.online;
}

void main() {
  testWidgets(
    'OrderDetailPage shows offline cash recovery action for local outage cash order',
    (tester) async {
      final order = Order(
        id: 'local-1',
        saleId: 'local-1',
        number: 'LOCAL-001',
        status: 'pending',
        ticketStatus: 'UNPAID',
        placedAt: DateTime(2026, 3, 17, 9),
        orderType: 'take_away',
        paymentMethod: 'cash',
        totalUsd: 3.5,
        totalKhr: 14350,
        tenderCurrency: 'usd',
        tenderAmount: 0,
        changeAmount: 0,
        lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
        isLocalOutageOrder: true,
        localOutageState: SaleOutageOrderStates.localOpenOrderCaptured,
        localOutageIntentId: 'local-1',
        localOutageSourceMode: SaleOutageSourceModes.standardOpenOrder,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
            policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
            appConnectivityStatusProvider.overrideWith(
              _OnlineConnectivityNotifier.new,
            ),
          ],
          child: const MaterialApp(
            home: OrderDetailPage(orderNumber: 'LOCAL-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cash Recovery'), findsOneWidget);
      expect(find.text('Finalize Captured Cash Order'), findsOneWidget);
    },
  );
}
