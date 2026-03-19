import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
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

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession? _session;

  @override
  LoginState build() => LoginState(session: _session);
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

void main() {
  testWidgets(
    'OrderDetailPage shows queued cash replay state for queue-backed outage cash order',
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
        localOutageState: SaleOutageOrderStates.awaitingSettlement,
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
            loginControllerProvider.overrideWith(
              () => _StaticLoginController(_sessionForRole('cashier')),
            ),
          ],
          child: const MaterialApp(
            home: OrderDetailPage(orderIdentityKey: 'local:local-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offline Cash Replay'), findsOneWidget);
      expect(find.text('Settle Captured Cash Order'), findsNothing);
    },
  );

  testWidgets(
    'OrderDetailPage keeps legacy cash recovery action for pre-queue outage cash order',
    (tester) async {
      final order = Order(
        id: 'legacy-1',
        saleId: 'legacy-1',
        number: 'LOCAL-LEGACY',
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
        localOutageIntentId: 'legacy-1',
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
            loginControllerProvider.overrideWith(
              () => _StaticLoginController(_sessionForRole('cashier')),
            ),
          ],
          child: const MaterialApp(
            home: OrderDetailPage(orderIdentityKey: 'local:legacy-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cash Recovery'), findsOneWidget);
      expect(find.text('Settle Captured Cash Order'), findsOneWidget);
    },
  );

  testWidgets(
    'OrderDetailPage shows manual claim online submit action for recorded outage claim',
    (tester) async {
      final order = Order(
        id: 'local-2',
        saleId: 'local-2',
        number: 'LOCAL-002',
        status: 'pending',
        ticketStatus: 'UNPAID',
        placedAt: DateTime(2026, 3, 17, 9),
        orderType: 'take_away',
        paymentMethod: 'qr',
        totalUsd: 3.5,
        totalKhr: 14350,
        tenderCurrency: 'usd',
        tenderAmount: 3.5,
        changeAmount: 0,
        lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
        isLocalOutageOrder: true,
        localOutageState:
            SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
        localOutageIntentId: 'local-2',
        localOutageSourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
        localOutageClaimedPaymentMethod: 'KHQR',
        localOutageClaimedTenderAmount: 3.5,
        localOutageProofImageUrl: 'https://example.com/proof.jpg',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
            policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
            appConnectivityStatusProvider.overrideWith(
              _OnlineConnectivityNotifier.new,
            ),
            loginControllerProvider.overrideWith(
              () => _StaticLoginController(_sessionForRole('cashier')),
            ),
          ],
          child: const MaterialApp(
            home: OrderDetailPage(orderIdentityKey: 'local:local-2'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manual KHQR Claim'), findsOneWidget);
      expect(find.text('Submit Claim Online'), findsOneWidget);
    },
  );

  testWidgets(
    'OrderDetailPage shows manager review actions for submitted manual claim',
    (tester) async {
      final order = Order(
        id: 'order-1',
        saleId: 'order-1',
        number: 'LOCAL-003',
        status: 'pending',
        ticketStatus: 'UNPAID',
        placedAt: DateTime(2026, 3, 17, 9),
        orderType: 'take_away',
        paymentMethod: 'qr',
        totalUsd: 3.5,
        totalKhr: 14350,
        tenderCurrency: 'usd',
        tenderAmount: 3.5,
        changeAmount: 0,
        lines: const [OrderLine(name: 'Latte', modifiers: [], quantity: 1)],
        openTicketId: 'order-1',
        isLocalOutageOrder: true,
        localOutageState:
            SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
        localOutageIntentId: 'local-3',
        localOutageSourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
        localOutageClaimedPaymentMethod: 'KHQR',
        localOutageClaimedTenderAmount: 3.5,
        localOutageProofImageUrl: 'https://example.com/proof.jpg',
        localOutageBackendClaimId: 'claim-1',
        localOutageClaimSubmittedAt: DateTime(2026, 3, 17, 9, 10),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith(() => _StaticOrdersNotifier([order])),
            policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
            appConnectivityStatusProvider.overrideWith(
              _OnlineConnectivityNotifier.new,
            ),
            loginControllerProvider.overrideWith(
              () => _StaticLoginController(_sessionForRole('manager')),
            ),
          ],
          child: const MaterialApp(
            home: OrderDetailPage(orderIdentityKey: 'local:local-3'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Approve Claim'), findsOneWidget);
      expect(find.text('Reject Claim'), findsOneWidget);
    },
  );
}
