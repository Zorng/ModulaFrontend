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

  Future<void> loadCurrentBranchProfile() async {
    state = state.copyWith(
      isCurrentBranchLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final profile = await _repository.getCurrentBranchProfile();
      await _applyCurrentBranchProfile(profile, isCurrentBranchLoading: false);
    } catch (error) {
      _setCurrentBranchError(
        error,
        fallbackMessage: 'Failed to load current branch profile.',
      );
    }
  }

  Future<void> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
  }) async {
    final normalizedAccountId = khqrReceiverAccountId.trim();
    final normalizedReceiverName = khqrReceiverName.trim();
    if (normalizedAccountId.isEmpty || normalizedReceiverName.isEmpty) {
      state = state.copyWith(
        isKhqrReceiverUpdating: false,
        error: 'KHQR receiver account and name are required.',
        errorCode: BranchErrorCodes.orgBranchKhqrReceiverInvalid,
        errorStatusCode: 422,
      );
      return;
    }

    state = state.copyWith(
      isKhqrReceiverUpdating: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final profile = await _repository.updateCurrentBranchKhqrReceiver(
        khqrReceiverAccountId: normalizedAccountId,
        khqrReceiverName: normalizedReceiverName,
      );
      await _applyCurrentBranchProfile(profile, isKhqrReceiverUpdating: false);
    } catch (error) {
      _setKhqrReceiverError(
        error,
        fallbackMessage: 'Failed to update KHQR receiver account.',
      );
    }
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
        errorCode: BranchErrorCodes.branchContextRequired,
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

  List<BranchListItem> _mergeBranchProfileIntoList(BranchListItem profile) {
    final index = state.branches.indexWhere(
      (item) => item.branchId == profile.branchId,
    );
    if (index < 0) return state.branches;

    final updated = List<BranchListItem>.from(state.branches);
    updated[index] = updated[index].copyWith(
      tenantId: profile.tenantId,
      branchName: profile.branchName,
      status: profile.status,
      branchAddress: profile.branchAddress,
      contactNumber: profile.contactNumber,
      khqrReceiverAccountId: profile.khqrReceiverAccountId,
      khqrReceiverName: profile.khqrReceiverName,
      attendanceLocationVerificationMode:
          profile.attendanceLocationVerificationMode,
      workplaceLocation: profile.workplaceLocation,
    );
    return updated;
  }

  Future<void> _applyCurrentBranchProfile(
    BranchListItem profile, {
    bool? isCurrentBranchLoading,
    bool? isKhqrReceiverUpdating,
  }) async {
    final mergedBranches = _mergeBranchProfileIntoList(profile);
    state = state.copyWith(
      isCurrentBranchLoading:
          isCurrentBranchLoading ?? state.isCurrentBranchLoading,
      isKhqrReceiverUpdating:
          isKhqrReceiverUpdating ?? state.isKhqrReceiverUpdating,
      currentBranchProfile: profile,
      branches: mergedBranches,
    );

    try {
      final items = await _repository.loadAccessibleBranches();
      final refreshedBranches = items
          .map((item) {
            if (item.branchId != profile.branchId) return item;
            return item.copyWith(
              khqrReceiverAccountId: profile.khqrReceiverAccountId,
              khqrReceiverName: profile.khqrReceiverName,
              attendanceLocationVerificationMode:
                  profile.attendanceLocationVerificationMode,
              workplaceLocation: profile.workplaceLocation,
              branchAddress: profile.branchAddress,
              contactNumber: profile.contactNumber,
              status: profile.status,
              branchName: profile.branchName,
              tenantId: profile.tenantId,
            );
          })
          .toList(growable: false);
      state = state.copyWith(
        isCurrentBranchLoading:
            isCurrentBranchLoading ?? state.isCurrentBranchLoading,
        isKhqrReceiverUpdating:
            isKhqrReceiverUpdating ?? state.isKhqrReceiverUpdating,
        currentBranchProfile: profile,
        branches: refreshedBranches,
      );
    } catch (_) {
      // Keep the successfully updated current branch profile and merged list even
      // if the non-critical branch-list refresh fails.
    }
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

  void _setCurrentBranchError(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) {
      final normalizedCode = BranchErrorCodes.normalize(error.code);
      state = state.copyWith(
        isCurrentBranchLoading: false,
        error: error.message,
        errorCode: BranchErrorCodes.isCurrentBranchCode(normalizedCode)
            ? normalizedCode
            : _normalizeErrorCode(error.code),
        errorStatusCode: error.statusCode,
      );
      return;
    }

    state = state.copyWith(
      isCurrentBranchLoading: false,
      error: fallbackMessage,
      errorCode: _formatExceptionCode(error),
      errorStatusCode: null,
    );
  }

  void _setKhqrReceiverError(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) {
      final normalizedCode = BranchErrorCodes.normalize(error.code);
      state = state.copyWith(
        isKhqrReceiverUpdating: false,
        error: error.message,
        errorCode: BranchErrorCodes.isKhqrReceiverCode(normalizedCode)
            ? normalizedCode
            : _normalizeErrorCode(error.code),
        errorStatusCode: error.statusCode,
      );
      return;
    }

    state = state.copyWith(
      isKhqrReceiverUpdating: false,
      error: fallbackMessage,
      errorCode: _formatExceptionCode(error),
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

  String? _normalizeErrorCode(String? code) {
    return BranchErrorCodes.normalize(code);
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
