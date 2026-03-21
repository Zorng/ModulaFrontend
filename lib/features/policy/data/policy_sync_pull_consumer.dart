import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/features/policy/data/dto/policy_dto.dart';
import 'package:modular_pos/features/policy/data/policy_cache_store.dart';
import 'package:modular_pos/features/policy/data/policy_mapper.dart';

final policySyncPullConsumerProvider = Provider<SyncPullConsumer>((ref) {
  final cacheStore = ref.watch(policyCacheStoreProvider);
  return PolicySyncPullConsumer(cacheStore);
});

class PolicySyncPullConsumer implements SyncPullConsumer {
  PolicySyncPullConsumer(this._cacheStore);

  final PolicyCacheStore _cacheStore;

  static const _candidateKeys = <String>[
    'policy',
    'branchPolicy',
    'currentBranchPolicy',
    'currentBranch',
    'snapshot',
    'data',
  ];

  @override
  SyncModuleScope get scope => SyncModuleScope.policy;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required dynamic payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    final rawPolicy = _extractPolicyPayload(payload);
    if (rawPolicy.isEmpty) return;

    final dto = BranchPolicyDto.fromJson(rawPolicy);
    final policy = mapBranchPolicyDto(
      dto,
      tenantIdFallback: context.tenantId,
      branchIdFallback: context.branchId,
    );

    if (policy.tenantId.trim().isEmpty || policy.branchId.trim().isEmpty) {
      throw StateError(
        'Policy sync payload is missing tenant or branch context.',
      );
    }

    await _cacheStore.write(
      policy,
      syncCursorApplied: cursor,
      lastPullAt: pulledAt,
    );
  }

  Map<String, dynamic> _extractPolicyPayload(dynamic payload) {
    final root = ApiContract.asJsonMap(payload);
    if (_looksLikePolicy(root)) return root;

    for (final key in _candidateKeys) {
      final candidate = ApiContract.asJsonMap(root[key]);
      if (_looksLikePolicy(candidate)) {
        return candidate;
      }
    }

    return const <String, dynamic>{};
  }

  bool _looksLikePolicy(Map<String, dynamic> value) {
    if (value.isEmpty) return false;
    return value.containsKey('saleVatEnabled') ||
        value.containsKey('saleVatRatePercent') ||
        value.containsKey('saleFxRateKhrPerUsd') ||
        value.containsKey('saleKhrRoundingEnabled') ||
        value.containsKey('saleAllowPayLater') ||
        value.containsKey('saleAllowManualExternalPaymentClaim');
  }
}
