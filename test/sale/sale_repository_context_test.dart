import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

void main() {
  SaleRepository buildRepository({
    LoginState? loginState,
    BranchState? branchState,
    CashSessionState? cashSessionState,
    PolicyState? policyState,
  }) {
    return SaleRepository(
      SaleApi(Dio()),
      loginStateReader: () => loginState ?? const LoginState(),
      branchStateReader: () => branchState ?? const BranchState(),
      cashSessionStateReader: () =>
          cashSessionState ?? const CashSessionState(),
      policyStateReader: () => policyState ?? const PolicyState(),
    );
  }

  test(
    'getSaleContext blocks unauthorized access before branch checks',
    () async {
      final repo = buildRepository();

      final context = await repo.getSaleContext(branchId: 'branch-1');

      expect(context.reasonCode, SaleCheckoutReasonCodes.unauthorized);
      expect(context.canMutateCart, isFalse);
      expect(context.canCheckout, isFalse);
      expect(context.canPlacePayLater, isFalse);
    },
  );

  test(
    'getSaleContext allows cart mutation but blocks checkout without cash session',
    () async {
      final repo = buildRepository(
        loginState: _authenticatedLoginState(),
        branchState: const BranchState(
          branches: [
            BranchListItem(
              branchId: 'branch-1',
              tenantId: 'tenant-1',
              branchName: 'Main',
              status: 'ACTIVE',
            ),
          ],
        ),
        policyState: const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleAllowPayLater: true,
          ),
        ),
      );

      final context = await repo.getSaleContext(branchId: 'branch-1');

      expect(context.branchActive, isTrue);
      expect(context.cashSessionOpen, isFalse);
      expect(context.reasonCode, SaleCheckoutReasonCodes.cashSessionRequired);
      expect(context.canMutateCart, isTrue);
      expect(context.canCheckout, isFalse);
      expect(context.canPlacePayLater, isFalse);
    },
  );

  test(
    'getSaleContext falls back to auth branch assignment when branch state is not hydrated',
    () async {
      final repo = buildRepository(
        loginState: _authenticatedLoginState(),
        branchState: const BranchState(),
        policyState: const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleAllowPayLater: true,
          ),
        ),
      );

      final context = await repo.getSaleContext(branchId: 'branch-1');

      expect(context.branchActive, isTrue);
      expect(context.branchFrozen, isFalse);
      expect(context.reasonCode, SaleCheckoutReasonCodes.cashSessionRequired);
      expect(context.canMutateCart, isTrue);
      expect(context.canCheckout, isFalse);
    },
  );

  test(
    'getSaleContext trusts branch token context even when local branch metadata is absent',
    () async {
      final session = _authenticatedLoginState().copyWith(
        session: AuthSession(
          memberships: const [],
          activeTenantId: 'tenant-1',
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          accessTokenExpiresAt: DateTime(2026, 3, 8),
          refreshTokenExpiresAt: DateTime(2026, 3, 9),
          user: User(
            id: 'user-1',
            name: 'Test User',
            role: 'cashier',
            tenantId: 'tenant-1',
            phone: '+85512345678',
            branches: const [],
          ),
        ),
      );

      final repo = buildRepository(
        loginState: session,
        branchState: const BranchState(),
        policyState: const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleAllowPayLater: true,
          ),
        ),
      );

      final context = await repo.getSaleContext(branchId: 'branch-1');

      expect(context.branchActive, isTrue);
      expect(context.branchFrozen, isFalse);
      expect(context.reasonCode, SaleCheckoutReasonCodes.cashSessionRequired);
      expect(context.canMutateCart, isTrue);
      expect(context.canCheckout, isFalse);
    },
  );

  test(
    'getSaleContext allows checkout and pay later when branch and session are ready',
    () async {
      final repo = buildRepository(
        loginState: _authenticatedLoginState(),
        branchState: const BranchState(
          branches: [
            BranchListItem(
              branchId: 'branch-1',
              tenantId: 'tenant-1',
              branchName: 'Main',
              status: 'ACTIVE',
            ),
          ],
        ),
        cashSessionState: CashSessionState(
          session: CashSession(
            id: 'session-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            openedByAccountId: 'acc-1',
            openedAt: DateTime(2026, 3, 7),
            status: CashSessionStatuses.open,
            openingFloatUsd: 20,
            openingFloatKhr: 80000,
            closedAt: null,
            closedByAccountId: null,
            closeNote: null,
            totalPaidInUsd: 0,
            totalPaidOutUsd: 0,
          ),
        ),
        policyState: const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleAllowPayLater: true,
          ),
        ),
      );

      final context = await repo.getSaleContext(branchId: 'branch-1');

      expect(context.reasonCode, isNull);
      expect(context.cashSessionOpen, isTrue);
      expect(context.canMutateCart, isTrue);
      expect(context.canCheckout, isTrue);
      expect(context.canPlacePayLater, isTrue);
    },
  );

  test(
    'getSaleContext blocks frozen branches even when session is open',
    () async {
      final repo = buildRepository(
        loginState: _authenticatedLoginState(),
        branchState: const BranchState(
          branches: [
            BranchListItem(
              branchId: 'branch-1',
              tenantId: 'tenant-1',
              branchName: 'Main',
              status: 'FROZEN',
            ),
          ],
        ),
        cashSessionState: CashSessionState(
          session: CashSession(
            id: 'session-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            openedByAccountId: 'acc-1',
            openedAt: DateTime(2026, 3, 7),
            status: CashSessionStatuses.open,
            openingFloatUsd: 20,
            openingFloatKhr: 80000,
            closedAt: null,
            closedByAccountId: null,
            closeNote: null,
            totalPaidInUsd: 0,
            totalPaidOutUsd: 0,
          ),
        ),
        policyState: const PolicyState(
          branchPolicy: BranchPolicy(
            branchId: 'branch-1',
            tenantId: 'tenant-1',
            saleAllowPayLater: true,
          ),
        ),
      );

      final context = await repo.getSaleContext(branchId: 'branch-1');

      expect(context.branchActive, isFalse);
      expect(context.branchFrozen, isTrue);
      expect(context.reasonCode, SaleCheckoutReasonCodes.branchFrozen);
      expect(context.canMutateCart, isFalse);
      expect(context.canCheckout, isFalse);
    },
  );
}

LoginState _authenticatedLoginState() {
  return LoginState(
    session: AuthSession(
      memberships: const [],
      activeTenantId: 'tenant-1',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      accessTokenExpiresAt: DateTime(2026, 3, 8),
      refreshTokenExpiresAt: DateTime(2026, 3, 9),
      user: User(
        id: 'user-1',
        name: 'Test User',
        role: 'cashier',
        tenantId: 'tenant-1',
        phone: '+85512345678',
        branches: [
          UserBranch(
            id: 'assignment-1',
            branchId: 'branch-1',
            name: 'Main',
            role: 'cashier',
            active: true,
          ),
        ],
      ),
    ),
  );
}
