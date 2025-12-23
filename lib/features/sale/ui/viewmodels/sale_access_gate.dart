import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';

class SaleAccessGate {
  const SaleAccessGate({
    required this.branchId,
    required this.requiresCashSessionForSales,
    required this.cashSessionOpen,
    required this.cashSessionLoading,
    required this.policiesLoading,
  });

  final String? branchId;
  final bool requiresCashSessionForSales;
  final bool cashSessionOpen;
  final bool cashSessionLoading;
  final bool policiesLoading;

  bool get isBlockedByCashSessionPolicy =>
      requiresCashSessionForSales && !cashSessionOpen;

  /// True when mutations (add to cart / checkout) are allowed right now.
  bool get canMutateCart =>
      !policiesLoading && !cashSessionLoading && !isBlockedByCashSessionPolicy;

  bool get canCreateDraftSale => !isBlockedByCashSessionPolicy;
  bool get canAddToCart => canCreateDraftSale;
  bool get canCheckout => canCreateDraftSale;

  String? get blockingMessage => isBlockedByCashSessionPolicy
      ? 'Cash session required. Start one to begin selling.'
      : null;
}

/// Source-of-truth gate used by Sale UI + viewmodels to decide whether the user
/// can create draft sales, add items, and checkout.
final saleAccessGateProvider = Provider<SaleAccessGate>((ref) {
  final branchId = ref.watch(authActiveBranchIdProvider);

  final policyState = ref.watch(policyNotifierProvider);
  final requiresSession =
      policyState.cashSessionPolicy.cashRequireSessionForSales;

  final cashSessionState = ref.watch(cashSessionViewModelProvider);
  final sessionOpen = cashSessionState.sessionStatus == SessionStatus.open;

  return SaleAccessGate(
    branchId: branchId,
    requiresCashSessionForSales: requiresSession,
    cashSessionOpen: sessionOpen,
    cashSessionLoading: cashSessionState.isLoading,
    policiesLoading: policyState.isLoading,
  );
});
