import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

class SaleAccessGate {
  const SaleAccessGate({
    required this.branchId,
    required this.contextLoading,
    required this.branchActive,
    required this.branchFrozen,
    required this.cashSessionOpen,
    required this.canMutateCart,
    required this.canCheckout,
    required this.canPlacePayLater,
    this.reasonCode,
    this.reasonMessage,
  });

  final String? branchId;
  final bool contextLoading;
  final bool branchActive;
  final bool branchFrozen;
  final bool cashSessionOpen;
  final bool canMutateCart;
  final bool canCheckout;
  final bool canPlacePayLater;
  final String? reasonCode;
  final String? reasonMessage;

  bool get isBlockedByCashSessionPolicy =>
      reasonCode == SaleCheckoutReasonCodes.cashSessionRequired;

  bool get cashSessionLoading => contextLoading;
  bool get isLoading => contextLoading;

  bool get hasBlockingReason => !contextLoading && reasonCode != null;

  /// True when mutations (add to cart / checkout) are allowed right now.
  bool get canCreateDraftSale {
    if (reasonCode == null) return true;
    switch (reasonCode) {
      case SaleCheckoutReasonCodes.unauthorized:
      case SaleCheckoutReasonCodes.branchRequired:
      case SaleCheckoutReasonCodes.branchFrozen:
      case SaleCheckoutReasonCodes.unknownError:
        return false;
      default:
        return true;
    }
  }

  bool get canAddToCart => canCreateDraftSale;
  bool get showCashSessionAction =>
      reasonCode == SaleCheckoutReasonCodes.cashSessionRequired;

  String? get blockingMessage {
    if (contextLoading) {
      return 'Checking sale access. Please wait.';
    }
    if (reasonMessage != null && reasonMessage!.trim().isNotEmpty) {
      return reasonMessage!.trim();
    }
    return _fallbackMessageForReason(reasonCode);
  }

  static String? _fallbackMessageForReason(String? code) {
    switch (code) {
      case SaleCheckoutReasonCodes.unauthorized:
        return 'Your account no longer has access to sell.';
      case SaleCheckoutReasonCodes.branchRequired:
        return 'Branch context is missing. Please switch to an active branch.';
      case SaleCheckoutReasonCodes.branchFrozen:
        return 'This branch is frozen. Sale writes are currently blocked.';
      case SaleCheckoutReasonCodes.cashSessionRequired:
        return 'Cash session required. Start one to begin selling.';
      case SaleCheckoutReasonCodes.payLaterDisabled:
        return 'Pay-later is currently disabled for this branch.';
      case SaleCheckoutReasonCodes.offlineUnreachable:
        return 'Action unavailable while offline. Please reconnect and retry.';
      case SaleCheckoutReasonCodes.unknownError:
        return 'Unable to verify sale access right now.';
      case null:
        return null;
      default:
        return 'This action is currently blocked by sale policy.';
    }
  }
}

final _saleContextProvider = FutureProvider.family<SaleContextDto, String>((
  ref,
  branchId,
) async {
  // Refresh context when session changes to avoid stale guards after open/close.
  ref.watch(
    cashSessionViewModelProvider.select(
      (state) => '${state.sessionStatus}:${state.sessionId ?? ''}',
    ),
  );

  final repo = ref.watch(saleRepositoryProvider);
  return repo.getSaleContext(branchId: branchId);
});

/// Sale access prefers explicit workspace branch context, but falls back to
/// the auth-derived active branch assignment when the workspace is still global.
final saleAccessBranchIdProvider = Provider<String?>((ref) {
  final workspaceBranchId =
      (ref.watch(activeBranchContextIdProvider) ?? '').trim();
  if (workspaceBranchId.isNotEmpty) return workspaceBranchId;

  final authBranchId = (ref.watch(authActiveBranchIdProvider) ?? '').trim();
  return authBranchId.isEmpty ? null : authBranchId;
});

/// Source-of-truth gate used by Sale UI + viewmodels to decide whether the user
/// can create draft sales, add items, and checkout.
final saleAccessGateProvider = Provider<SaleAccessGate>((ref) {
  final branchId = ref.watch(saleAccessBranchIdProvider);
  if (branchId == null || branchId.trim().isEmpty) {
    return const SaleAccessGate(
      branchId: null,
      contextLoading: false,
      branchActive: false,
      branchFrozen: false,
      cashSessionOpen: false,
      canMutateCart: false,
      canCheckout: false,
      canPlacePayLater: false,
      reasonCode: SaleCheckoutReasonCodes.branchRequired,
    );
  }

  final contextAsync = ref.watch(_saleContextProvider(branchId));
  if (contextAsync.isLoading) {
    return SaleAccessGate(
      branchId: branchId,
      contextLoading: true,
      branchActive: true,
      branchFrozen: false,
      cashSessionOpen: false,
      canMutateCart: false,
      canCheckout: false,
      canPlacePayLater: false,
    );
  }

  if (contextAsync.hasError) {
    return SaleAccessGate(
      branchId: branchId,
      contextLoading: false,
      branchActive: false,
      branchFrozen: false,
      cashSessionOpen: false,
      canMutateCart: false,
      canCheckout: false,
      canPlacePayLater: false,
      reasonCode: SaleCheckoutReasonCodes.unknownError,
      reasonMessage: 'Unable to verify sale access right now.',
    );
  }

  final context = contextAsync.requireValue;
  return SaleAccessGate(
    branchId: branchId,
    contextLoading: false,
    branchActive: context.branchActive,
    branchFrozen: context.branchFrozen,
    cashSessionOpen: context.cashSessionOpen,
    canMutateCart: context.canMutateCart,
    canCheckout: context.canCheckout,
    canPlacePayLater: context.canPlacePayLater,
    reasonCode: context.reasonCode,
    reasonMessage: context.reasonMessage,
  );
});
