import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

enum BranchCreateFlowStatus {
  idle,
  initiating,
  pendingPayment,
  confirming,
  confirmed,
  failed,
}

enum BranchNavigationIntent {
  none,
  tenantSelection,
}

enum BranchSelectionResult {
  success,
  tenantSelectionRequired,
  failed,
}

class BranchState {
  static const Object _unset = Object();

  const BranchState({
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.errorStatusCode,
    this.branches = const <BranchListItem>[],
    this.activeTenantId,
    this.tenantName = '',
    this.roleKey = '',
    this.canManageTenant = false,
    this.membershipId = '',
    this.searchQuery = '',
    this.createFlowStatus = BranchCreateFlowStatus.idle,
    this.activationDraft,
    this.activationResult,
    this.selectedContextTokens,
    this.selectedBranchId,
    this.navigationIntent = BranchNavigationIntent.none,
  });

  final bool isLoading;
  final String? error;
  final String? errorCode;
  final int? errorStatusCode;

  final List<BranchListItem> branches;
  final String? activeTenantId;
  final String tenantName;
  final String roleKey;
  final bool canManageTenant;
  final String membershipId;
  final String searchQuery;

  final BranchCreateFlowStatus createFlowStatus;
  final BranchActivationDraft? activationDraft;
  final BranchActivationResult? activationResult;

  final BranchContextTokens? selectedContextTokens;
  final String? selectedBranchId;
  final BranchNavigationIntent navigationIntent;

  List<BranchListItem> get visibleBranches {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return branches;

    return branches
        .where((item) {
          final haystack = [
            item.branchName,
            item.branchId,
            item.branchAddress ?? '',
            item.contactNumber ?? '',
          ].join('|').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  BranchState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    Object? errorStatusCode = _unset,
    List<BranchListItem>? branches,
    Object? activeTenantId = _unset,
    String? tenantName,
    String? roleKey,
    bool? canManageTenant,
    String? membershipId,
    String? searchQuery,
    BranchCreateFlowStatus? createFlowStatus,
    Object? activationDraft = _unset,
    Object? activationResult = _unset,
    Object? selectedContextTokens = _unset,
    Object? selectedBranchId = _unset,
    BranchNavigationIntent? navigationIntent,
  }) {
    return BranchState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      errorStatusCode: identical(errorStatusCode, _unset)
          ? this.errorStatusCode
          : errorStatusCode as int?,
      branches: branches ?? this.branches,
      activeTenantId: identical(activeTenantId, _unset)
          ? this.activeTenantId
          : activeTenantId as String?,
      tenantName: tenantName ?? this.tenantName,
      roleKey: roleKey ?? this.roleKey,
      canManageTenant: canManageTenant ?? this.canManageTenant,
      membershipId: membershipId ?? this.membershipId,
      searchQuery: searchQuery ?? this.searchQuery,
      createFlowStatus: createFlowStatus ?? this.createFlowStatus,
      activationDraft: identical(activationDraft, _unset)
          ? this.activationDraft
          : activationDraft as BranchActivationDraft?,
      activationResult: identical(activationResult, _unset)
          ? this.activationResult
          : activationResult as BranchActivationResult?,
      selectedContextTokens: identical(selectedContextTokens, _unset)
          ? this.selectedContextTokens
          : selectedContextTokens as BranchContextTokens?,
      selectedBranchId: identical(selectedBranchId, _unset)
          ? this.selectedBranchId
          : selectedBranchId as String?,
      navigationIntent: navigationIntent ?? this.navigationIntent,
    );
  }
}
