import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';
import 'package:modular_pos/features/cash_session/ui/view/cash_session/cashier_cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/current_session_summary_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/reporting/domain/models/cash_session_status.dart';
import 'package:modular_pos/features/reporting/domain/models/x_report.dart';

import '../test_utils/pump_app.dart';

class _StaticCashSessionViewModel extends CashSessionViewModel {
  _StaticCashSessionViewModel(this._state);

  final CashSessionState _state;

  @override
  CashSessionState build() => _state;
}

void main() {
  testWidgets(
    'shows passive workspace freshness banner for cached offline state',
    (tester) async {
      final state = CashSessionState(
        isLoading: false,
        error: 'This cash-session action is unavailable while offline.',
        errorCode: 'OFFLINE_UNREACHABLE',
        currentUserAccountId: 'user-a',
        session: CashSession(
          id: 'session-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          openedByAccountId: 'user-a',
          openedByName: 'John Smith',
          openedAt: DateTime.utc(2026, 3, 8, 9),
          status: CashSessionStatuses.open,
          openingFloatUsd: 25,
          openingFloatKhr: 100000,
          closedAt: null,
          closedByAccountId: null,
          closedByName: null,
          closeNote: null,
          totalPaidInUsd: 0,
          totalPaidOutUsd: 0,
        ),
      );

      await pumpApp(
        tester,
        const CashSessionScreen(showAppBar: false),
        overrides: [
          authActiveBranchProvider.overrideWithValue(
            const UserBranch(
              id: 'assign-1',
              branchId: 'branch-1',
              name: 'Branch A',
              role: 'cashier',
              active: true,
            ),
          ),
          cashSessionViewModelProvider.overrideWith(
            () => _StaticCashSessionViewModel(state),
          ),
          branchWorkspaceSyncFreshnessProvider.overrideWith(
            (ref) async => const SyncWorkspaceFreshness(
              kind: SyncWorkspaceFreshnessKind.staleUsable,
              message: 'Offline: showing last synced workspace data.',
            ),
          ),
          currentSessionSummaryProvider.overrideWith((ref) async => null),
        ],
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Offline: showing last synced workspace data.'),
        findsOneWidget,
      );
      expect(find.text('Failed to load cash session'), findsNothing);
    },
  );

  testWidgets(
    'shows occupied state and hides normal close action when another account owns the open session',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = CashSessionState(
        isLoading: false,
        currentUserAccountId: 'user-b',
        sales: [
          CashSessionSale(
            saleId: 'sale-1',
            status: CashSessionSaleStatuses.finalized,
            paymentMethod: 'CASH',
            saleType: 'TAKEAWAY',
            finalizedAt: DateTime.utc(2026, 3, 8, 9, 30),
            totalItems: 3,
            grandTotalUsd: 7.5,
            grandTotalKhr: 30750,
            cashierAccountId: 'user-a',
            cashierName: 'John Smith',
            voidedAt: null,
          ),
        ],
        session: CashSession(
          id: 'session-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          openedByAccountId: 'user-a',
          openedByName: 'John Smith',
          openedAt: DateTime.utc(2026, 3, 8, 9),
          status: CashSessionStatuses.open,
          openingFloatUsd: 25,
          openingFloatKhr: 100000,
          closedAt: null,
          closedByAccountId: null,
          closedByName: null,
          closeNote: null,
          totalPaidInUsd: 0,
          totalPaidOutUsd: 0,
        ),
      );

      await pumpApp(
        tester,
        const CashSessionScreen(showAppBar: false),
        overrides: [
          authActiveBranchProvider.overrideWithValue(
            const UserBranch(
              id: 'assign-1',
              branchId: 'branch-1',
              name: 'Branch A',
              role: 'cashier',
              active: true,
            ),
          ),
          cashSessionViewModelProvider.overrideWith(
            () => _StaticCashSessionViewModel(state),
          ),
          currentSessionSummaryProvider.overrideWith(
            (ref) => Future.value(
              const XReportDetail(
                id: 'session-1',
                status: CashSessionStatus.open,
                openedByName: 'John Smith',
                openedAt: null,
                closedAt: null,
                openingFloatUsd: 25,
                openingFloatKhr: 100000,
                totalSalesKhqrUsd: 0,
                totalSalesKhqrKhr: 0,
                totalSalesCashUsd: 7.5,
                totalSalesCashKhr: 30750,
                totalPaidInUsd: 0,
                totalPaidInKhr: 0,
                totalPaidOutUsd: 0,
                totalPaidOutKhr: 0,
                expectedCashUsd: 32.5,
                expectedCashKhr: 130750,
              ),
            ),
          ),
        ],
      );

      expect(find.text('John Smith'), findsWidgets);
      expect(find.text('Current Session Summary'), findsNothing);
      expect(find.text('Session Action'), findsOneWidget);
      expect(find.text('Opened by'), findsOneWidget);
      expect(find.text('Session Sales'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Takeaway'), findsOneWidget);
      expect(find.textContaining('John Smith at'), findsOneWidget);
      expect(find.text('Close Cash Session'), findsNothing);
    },
  );
}
