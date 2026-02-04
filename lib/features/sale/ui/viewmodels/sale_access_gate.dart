import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

class SaleAccessGate {
  const SaleAccessGate({
    required this.branchId,
    required this.cashSessionOpen,
    required this.cashSessionLoading,
    required this.useMockRepository,
  });

  final String? branchId;
  final bool cashSessionOpen;
  final bool cashSessionLoading;
  final bool useMockRepository;

  bool get isBlockedByCashSessionPolicy =>
      !useMockRepository && !cashSessionOpen;

  /// True when mutations (add to cart / checkout) are allowed right now.
  bool get canMutateCart =>
      !cashSessionLoading && !isBlockedByCashSessionPolicy;

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

  final cashSessionState = ref.watch(cashSessionViewModelProvider);
  final sessionOpen = cashSessionState.sessionStatus == SessionStatus.open;

  final useMock = ref.watch(useMockSaleRepositoryProvider);

  return SaleAccessGate(
    branchId: branchId,
    cashSessionOpen: sessionOpen,
    cashSessionLoading: cashSessionState.isLoading,
    useMockRepository: useMock,
  );
});
