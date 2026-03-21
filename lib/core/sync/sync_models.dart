import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/sync_device_id_store.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

enum SyncModuleScope {
  policy('policy'),
  cashSession('cashSession'),
  menu('menu'),
  discount('discount'),
  inventory('inventory'),
  saleOrder('saleOrder'),
  shift('shift'),
  attendance('attendance'),
  operationalNotification('operationalNotification');

  const SyncModuleScope(this.apiValue);

  final String apiValue;
}

String buildModuleScopeSetKey(Iterable<SyncModuleScope> scopes) {
  final values = scopes.map((scope) => scope.apiValue).toList()..sort();
  return values.join('|');
}

String buildSyncPullRunKey({
  required SyncPullContext context,
  required String scopeSetKey,
}) {
  return [
    context.deviceId.trim(),
    context.tenantId.trim(),
    context.branchId.trim(),
    context.accountId.trim(),
    scopeSetKey.trim(),
  ].join('|');
}

class SyncPullContext {
  const SyncPullContext({
    required this.deviceId,
    required this.tenantId,
    this.branchId = '',
    this.accountId = '',
  });

  final String deviceId;
  final String tenantId;
  final String branchId;
  final String accountId;
}

class SyncPullEnvelope {
  const SyncPullEnvelope({
    required this.cursor,
    required this.pulledAt,
    required this.payloadByScope,
    required this.rawData,
  });

  final String? cursor;
  final DateTime pulledAt;
  final Map<String, dynamic> payloadByScope;
  final Map<String, dynamic> rawData;
}

enum SyncPullRunStatus { idle, running, success, failure }

class SyncPullRunState {
  const SyncPullRunState({
    this.status = SyncPullRunStatus.idle,
    this.moduleScopeSetKey,
    this.runKey,
    this.lastRunAt,
    this.lastErrorCode,
  });

  final SyncPullRunStatus status;
  final String? moduleScopeSetKey;
  final String? runKey;
  final DateTime? lastRunAt;
  final String? lastErrorCode;

  SyncPullRunState copyWith({
    SyncPullRunStatus? status,
    String? moduleScopeSetKey,
    String? runKey,
    Object? lastRunAt = _unset,
    Object? lastErrorCode = _unset,
  }) {
    return SyncPullRunState(
      status: status ?? this.status,
      moduleScopeSetKey: moduleScopeSetKey ?? this.moduleScopeSetKey,
      runKey: runKey ?? this.runKey,
      lastRunAt: identical(lastRunAt, _unset)
          ? this.lastRunAt
          : lastRunAt as DateTime?,
      lastErrorCode: identical(lastErrorCode, _unset)
          ? this.lastErrorCode
          : lastErrorCode as String?,
    );
  }

  static const _unset = Object();
}

final syncPullContextProvider = Provider<SyncPullContext?>((ref) {
  final tenantId =
      (ref.watch(authTenantIdProvider) ??
              ref.watch(loginControllerProvider).session?.activeTenantId ??
              ref.watch(loginControllerProvider).session?.user.tenantId ??
              '')
          .trim();
  final branchId = (ref.watch(activeBranchContextIdProvider) ?? '').trim();
  final accountId = (ref.watch(loginControllerProvider).session?.user.id ?? '')
      .trim();
  final deviceIdAsync = ref.watch(syncResolvedDeviceIdProvider);

  return switch (deviceIdAsync) {
    AsyncData(:final value) when tenantId.isNotEmpty => SyncPullContext(
      deviceId: value,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
    ),
    _ => null,
  };
});

final syncResolvedDeviceIdProvider = FutureProvider<String>((ref) async {
  return ref.read(syncDeviceIdStoreProvider).getOrCreate();
});
