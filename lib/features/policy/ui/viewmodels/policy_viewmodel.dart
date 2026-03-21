import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/policy/data/policy_cache_store.dart';
import 'package:modular_pos/features/policy/data/policy_error_codes.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

final policyNotifierProvider = NotifierProvider<PolicyNotifier, PolicyState>(
  PolicyNotifier.new,
);

final policyRequestTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 12),
);

final policyBranchContextProvider = Provider<PolicyBranchContext?>((ref) {
  final tenantId = (ref.watch(authTenantIdProvider) ?? '').trim();
  final branchId = (ref.watch(activeBranchContextIdProvider) ?? '').trim();
  if (tenantId.isEmpty || branchId.isEmpty) return null;
  return PolicyBranchContext(tenantId: tenantId, branchId: branchId);
});

class PolicyState {
  static const _unset = Object();

  const PolicyState({
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.isOffline = false,
    this.isStale = false,
    this.branchPolicy = const BranchPolicy(),
  });

  final bool isLoading;
  final String? error;
  final String? errorCode;
  final bool isOffline;
  final bool isStale;
  final BranchPolicy branchPolicy;

  PolicyState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    bool? isOffline,
    bool? isStale,
    BranchPolicy? branchPolicy,
  }) {
    return PolicyState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      isOffline: isOffline ?? this.isOffline,
      isStale: isStale ?? this.isStale,
      branchPolicy: branchPolicy ?? this.branchPolicy,
    );
  }
}

class PolicyNotifier extends Notifier<PolicyState> {
  PolicyRepository get _repo => ref.read(policyRepositoryProvider);
  PolicyCacheStore get _cache => ref.read(policyCacheStoreProvider);
  Duration get _requestTimeout => ref.read(policyRequestTimeoutProvider);

  @override
  PolicyState build() {
    return const PolicyState(isLoading: false);
  }

  Future<void> load() async {
    final requestedContext = ref.read(policyBranchContextProvider);
    final matchesCurrentContext = _matchesContext(
      state.branchPolicy,
      requestedContext,
    );

    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      isOffline: false,
      isStale: false,
      branchPolicy: matchesCurrentContext
          ? state.branchPolicy
          : const BranchPolicy(),
    );

    if (requestedContext != null) {
      final cachedPolicy = await _cache.read(
        tenantId: requestedContext.tenantId,
        branchId: requestedContext.branchId,
      );
      if (cachedPolicy != null &&
          ref.read(policyBranchContextProvider) == requestedContext) {
        state = state.copyWith(
          isLoading: true,
          error: null,
          errorCode: null,
          isOffline: false,
          isStale: false,
          branchPolicy: cachedPolicy,
        );
      }
    }

    try {
      final branchPolicy = await _repo.fetchCurrentBranchPolicy().timeout(
        _requestTimeout,
      );
      await _cache.write(branchPolicy);
      if (ref.read(policyBranchContextProvider) != requestedContext) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        isOffline: false,
        isStale: false,
        branchPolicy: branchPolicy,
      );
    } catch (e) {
      final mapped = _mapPolicyError(e);
      if (ref.read(policyBranchContextProvider) != requestedContext) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
        isOffline: mapped.isOffline,
        isStale: _hasLoadedPolicy(state.branchPolicy),
      );
    }
  }

  void reset() {
    state = const PolicyState(isLoading: false);
  }

  Future<void> updateVat({
    required bool enabled,
    required double ratePercent,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      isOffline: false,
    );
    try {
      final branchPolicy = await _repo
          .updateCurrentBranchPolicy(
            saleVatEnabled: enabled,
            saleVatRatePercent: ratePercent,
          )
          .timeout(_requestTimeout);
      await _cache.write(branchPolicy);
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        isOffline: false,
        isStale: false,
        branchPolicy: branchPolicy,
      );
    } catch (e) {
      final mapped = _mapPolicyError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
        isOffline: mapped.isOffline,
        isStale: _hasLoadedPolicy(state.branchPolicy),
      );
    }
  }

  Future<void> updateCurrency(double fxRateKhrPerUsd) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      isOffline: false,
    );
    try {
      final branchPolicy = await _repo
          .updateCurrentBranchPolicy(saleFxRateKhrPerUsd: fxRateKhrPerUsd)
          .timeout(_requestTimeout);
      await _cache.write(branchPolicy);
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        isOffline: false,
        isStale: false,
        branchPolicy: branchPolicy,
      );
    } catch (e) {
      final mapped = _mapPolicyError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
        isOffline: mapped.isOffline,
        isStale: _hasLoadedPolicy(state.branchPolicy),
      );
    }
  }

  Future<void> updateRounding({
    bool? roundingEnabled,
    String? roundingMode,
    String? roundingGranularity,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      isOffline: false,
    );
    try {
      final branchPolicy = await _repo
          .updateCurrentBranchPolicy(
            saleKhrRoundingEnabled: roundingEnabled,
            saleKhrRoundingMode: roundingMode,
            saleKhrRoundingGranularity: roundingGranularity,
          )
          .timeout(_requestTimeout);
      await _cache.write(branchPolicy);
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        isOffline: false,
        isStale: false,
        branchPolicy: branchPolicy,
      );
    } catch (e) {
      final mapped = _mapPolicyError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
        isOffline: mapped.isOffline,
        isStale: _hasLoadedPolicy(state.branchPolicy),
      );
    }
  }

  Future<void> updatePayLater({required bool enabled}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      isOffline: false,
    );
    try {
      final branchPolicy = await _repo
          .updateCurrentBranchPolicy(saleAllowPayLater: enabled)
          .timeout(_requestTimeout);
      await _cache.write(branchPolicy);
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        isOffline: false,
        isStale: false,
        branchPolicy: branchPolicy,
      );
    } catch (e) {
      final mapped = _mapPolicyError(e);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
        isOffline: mapped.isOffline,
        isStale: _hasLoadedPolicy(state.branchPolicy),
      );
    }
  }
}

bool _hasLoadedPolicy(BranchPolicy policy) {
  return policy.branchId.trim().isNotEmpty || policy.tenantId.trim().isNotEmpty;
}

bool _matchesContext(BranchPolicy policy, PolicyBranchContext? context) {
  if (context == null) return false;
  return policy.tenantId.trim() == context.tenantId &&
      policy.branchId.trim() == context.branchId;
}

_PolicyErrorView _mapPolicyError(Object error) {
  if (error is TimeoutException) {
    return const _PolicyErrorView(
      message: 'Policy request timed out. Check your connection and try again.',
      code: PolicyErrorCodes.offlineUnreachable,
      isOffline: true,
    );
  }
  if (error is ApiClientException) {
    final code = PolicyErrorCodes.normalize(error.code);
    final isOffline = PolicyErrorCodes.isOffline(code);
    return _PolicyErrorView(
      message: error.message,
      code: code,
      isOffline: isOffline,
    );
  }
  return _PolicyErrorView(message: error.toString());
}

class _PolicyErrorView {
  const _PolicyErrorView({
    required this.message,
    this.code,
    this.isOffline = false,
  });

  final String message;
  final String? code;
  final bool isOffline;
}

class PolicyBranchContext {
  const PolicyBranchContext({required this.tenantId, required this.branchId});

  final String tenantId;
  final String branchId;

  @override
  bool operator ==(Object other) {
    return other is PolicyBranchContext &&
        other.tenantId == tenantId &&
        other.branchId == branchId;
  }

  @override
  int get hashCode => Object.hash(tenantId, branchId);
}
