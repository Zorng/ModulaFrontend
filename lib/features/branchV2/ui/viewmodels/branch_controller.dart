import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/data/branch_mapper.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/data/dto/branch_error_codes.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';

final branchControllerProvider =
    NotifierProvider<BranchController, BranchState>(BranchController.new);

class BranchController extends Notifier<BranchState> {
  BranchRepository get _repository => ref.read(branchRepositoryProvider);

  @override
  BranchState build() {
    final session = ref.watch(loginControllerProvider.select((s) => s.session));
    final activeTenantId = session?.activeTenantId ?? session?.user.tenantId;
    final tenantAccess = BranchMapper.resolveTenantAccess(
      activeTenantId: activeTenantId,
      memberships: session?.memberships ?? const [],
    );
    final tenantName = _tenantNameFor(
      activeTenantId: activeTenantId,
      memberships: session?.memberships ?? const [],
    );

    return stateOrFallback.copyWith(
      activeTenantId: tenantAccess.activeTenantId,
      tenantName: tenantName,
      roleKey: tenantAccess.roleKey,
      canManageTenant: tenantAccess.canManageTenant,
      membershipId: tenantAccess.membershipId,
    );
  }

  BranchState get stateOrFallback {
    try {
      return state;
    } catch (_) {
      return const BranchState();
    }
  }

  Future<void> loadInitial() async {
    await _loadBranches(showLoading: true);
  }

  Future<void> refreshBranches() async {
    await _loadBranches(showLoading: false);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void clearSearchQuery() {
    if (state.searchQuery.trim().isEmpty) return;
    state = state.copyWith(searchQuery: '');
  }

  Future<BranchSelectionResult> onBranchTileTap({
    required String branchId,
  }) async {
    final normalizedBranchId = branchId.trim();
    final selectedBranchName = state.branches
        .firstWhere(
          (branch) => branch.branchId == normalizedBranchId,
          orElse: () => const BranchListItem(
            branchId: '',
            tenantId: '',
            branchName: '',
            status: '',
          ),
        )
        .branchName
        .trim();
    if (normalizedBranchId.isEmpty) {
      state = state.copyWith(
        error: 'Branch ID is required.',
        errorCode: 'INVALID_BRANCH_ID',
        errorStatusCode: 422,
      );
      return BranchSelectionResult.failed;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final loginController = ref.read(loginControllerProvider.notifier);
      await loginController.selectBranch(normalizedBranchId);
      final loginState = ref.read(loginControllerProvider);

      final hasLoginError =
          loginState.error != null && loginState.error!.trim().isNotEmpty;
      if (hasLoginError) {
        final normalizedLoginCode = (loginState.errorCode ?? '')
            .trim()
            .toUpperCase();
        final normalizedLoginMessage = (loginState.error ?? '')
            .trim()
            .toUpperCase();
        if (normalizedLoginCode == 'TENANT_CONTEXT_REQUIRED' ||
            normalizedLoginMessage.contains('TENANT CONTEXT REQUIRED')) {
          state = state.copyWith(
            isLoading: false,
            error: null,
            errorCode: null,
            errorStatusCode: null,
            navigationIntent: BranchNavigationIntent.tenantSelection,
          );
          return BranchSelectionResult.tenantSelectionRequired;
        }
        state = state.copyWith(
          isLoading: false,
          error: loginState.error,
          errorCode: loginState.errorCode,
          errorStatusCode: loginState.errorStatusCode,
        );
        return BranchSelectionResult.failed;
      }

      if (loginState.requiresBranchSelection) {
        state = state.copyWith(
          isLoading: false,
          error: 'Branch context is still required.',
          errorCode: 'BRANCH_CONTEXT_REQUIRED',
          errorStatusCode: 409,
        );
        return BranchSelectionResult.failed;
      }

      final updatedSession = loginState.session;
      final resolvedBranchId = normalizedBranchId;
      ref
          .read(authActiveBranchOverrideProvider.notifier)
          .setOverride(resolvedBranchId);
      ref
          .read(authActiveBranchNameOverrideProvider.notifier)
          .setName(selectedBranchName);
      final tokens = updatedSession == null
          ? null
          : BranchContextTokens(
              accessToken: updatedSession.accessToken,
              refreshToken: updatedSession.refreshToken,
              tenantId:
                  (updatedSession.activeTenantId ??
                          updatedSession.user.tenantId)
                      .trim(),
              branchId: resolvedBranchId,
            );

      state = state.copyWith(
        isLoading: false,
        selectedContextTokens: tokens,
        selectedBranchId: tokens?.branchId ?? resolvedBranchId,
        navigationIntent: BranchNavigationIntent.none,
      );
      return BranchSelectionResult.success;
    } catch (error) {
      _setActionError(error, fallbackMessage: 'Failed to select branch.');
      return state.navigationIntent == BranchNavigationIntent.tenantSelection
          ? BranchSelectionResult.tenantSelectionRequired
          : BranchSelectionResult.failed;
    }
  }

  Future<void> initiateCreateBranch({
    required String branchName,
    String? intentId,
  }) async {
    final normalizedName = branchName.trim();
    if (normalizedName.isEmpty) {
      state = state.copyWith(
        createFlowStatus: BranchCreateFlowStatus.failed,
        error: 'Branch name is required.',
        errorCode: 'INVALID_INPUT',
        errorStatusCode: 422,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      createFlowStatus: BranchCreateFlowStatus.initiating,
      error: null,
      errorCode: null,
      errorStatusCode: null,
      activationResult: null,
    );

    try {
      final draft = await _repository.initiateBranchActivation(
        branchName: normalizedName,
        intentId: intentId,
      );
      state = state.copyWith(
        isLoading: false,
        createFlowStatus: BranchCreateFlowStatus.pendingPayment,
        activationDraft: draft,
      );
    } catch (error) {
      _setCreateFlowError(
        error,
        fallbackMessage: 'Failed to initiate branch activation.',
      );
    }
  }

  Future<void> confirmCreateBranch({
    String? draftId,
    required String paymentToken,
    String? intentId,
  }) async {
    final resolvedDraftId = (draftId ?? state.activationDraft?.draftId ?? '')
        .trim();
    if (resolvedDraftId.isEmpty) {
      state = state.copyWith(
        createFlowStatus: BranchCreateFlowStatus.failed,
        error: 'Activation draft ID is required.',
        errorCode: 'INVALID_DRAFT_ID',
        errorStatusCode: 422,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      createFlowStatus: BranchCreateFlowStatus.confirming,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final result = await _repository.confirmBranchActivation(
        draftId: resolvedDraftId,
        paymentToken: paymentToken.trim(),
        intentId: intentId,
      );
      await _loadBranches(
        showLoading: false,
        highlightBranchId: result.branchId,
        markNewBranchId: result.created ? result.branchId : null,
      );
      state = state.copyWith(
        isLoading: false,
        createFlowStatus: BranchCreateFlowStatus.confirmed,
        activationResult: result,
      );
    } catch (error) {
      _setCreateFlowError(
        error,
        fallbackMessage: 'Failed to confirm branch activation.',
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(error: null, errorCode: null, errorStatusCode: null);
  }

  void clearCreateFlow() {
    state = state.copyWith(
      createFlowStatus: BranchCreateFlowStatus.idle,
      activationDraft: null,
      activationResult: null,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );
  }

  void consumeNavigationIntent() {
    if (state.navigationIntent == BranchNavigationIntent.none) return;
    state = state.copyWith(navigationIntent: BranchNavigationIntent.none);
  }

  Future<void> _loadBranches({
    required bool showLoading,
    String? highlightBranchId,
    String? markNewBranchId,
  }) async {
    if (state.activeTenantId == null || state.activeTenantId!.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        errorStatusCode: null,
        navigationIntent: BranchNavigationIntent.tenantSelection,
      );
      return;
    }

    state = state.copyWith(
      isLoading: showLoading ? true : state.isLoading,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final items = await _repository.loadAccessibleBranches();
      final normalizedHighlight = (highlightBranchId ?? '').trim();
      final normalizedNew = (markNewBranchId ?? '').trim();
      final normalizedItems = items
          .map((item) {
            final shouldHighlight =
                normalizedHighlight.isNotEmpty &&
                item.branchId == normalizedHighlight;
            final isNew =
                normalizedNew.isNotEmpty && item.branchId == normalizedNew;
            return item.copyWith(
              shouldHighlight: shouldHighlight,
              isNew: isNew,
            );
          })
          .toList(growable: false);
      state = state.copyWith(isLoading: false, branches: normalizedItems);
    } catch (error) {
      _setActionError(error, fallbackMessage: 'Failed to load branches.');
    }
  }

  void _setActionError(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) {
      final code = (error.code ?? '').trim().toUpperCase();
      final message = error.message.trim().toUpperCase();
      if (code == 'TENANT_CONTEXT_REQUIRED' ||
          message.contains('TENANT CONTEXT REQUIRED')) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          errorCode: null,
          errorStatusCode: null,
          navigationIntent: BranchNavigationIntent.tenantSelection,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: error.message,
        errorCode: error.code,
        errorStatusCode: error.statusCode,
      );
      return;
    }

    final code = _formatExceptionCode(error);
    state = state.copyWith(
      isLoading: false,
      error: fallbackMessage,
      errorCode: code,
      errorStatusCode: null,
    );
  }

  void _setCreateFlowError(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) {
      final normalizedCode = (error.code ?? '').trim().toUpperCase();
      state = state.copyWith(
        isLoading: false,
        createFlowStatus: BranchCreateFlowStatus.failed,
        error: error.message,
        errorCode: normalizedCode.isEmpty ? error.code : normalizedCode,
        errorStatusCode: error.statusCode,
      );
      return;
    }

    final code = _formatExceptionCode(error);
    final normalizedCode = code?.toUpperCase();
    final branchCode = normalizedCode;
    final knownCode =
        BranchErrorCodes.isInitiateCode(branchCode) ||
        BranchErrorCodes.isConfirmCode(branchCode);

    state = state.copyWith(
      isLoading: false,
      createFlowStatus: BranchCreateFlowStatus.failed,
      error: fallbackMessage,
      errorCode: knownCode ? branchCode : code,
      errorStatusCode: null,
    );
  }

  String? _formatExceptionCode(Object error) {
    if (error is FormatException) {
      final code = error.message.trim().toUpperCase();
      if (code.isNotEmpty) return code;
    }
    return null;
  }

  String _tenantNameFor({
    required String? activeTenantId,
    required List<TenantMembership> memberships,
  }) {
    final tenantId = (activeTenantId ?? '').trim();
    if (tenantId.isEmpty) return '';

    for (final membership in memberships) {
      final currentTenantId = membership.tenantId.trim();
      if (currentTenantId != tenantId) continue;
      final tenantName = membership.tenantName.trim();
      if (tenantName.isNotEmpty) return tenantName;
    }
    return tenantId;
  }
}
