import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

enum SaleOutageRecoveryTrigger { contextChange, reconnect, manual }

enum SaleOutageRecoveryOutcome {
  success,
  noPending,
  partialFailure,
  skippedNoScope,
  skippedOffline,
  skippedInFlight,
  skippedCooldown,
}

class SaleOutageRecoveryResult {
  const SaleOutageRecoveryResult({
    required this.trigger,
    required this.outcome,
    this.scope,
    this.recoveredCount = 0,
    this.failedCount = 0,
  });

  final SaleOutageRecoveryTrigger trigger;
  final SaleOutageRecoveryOutcome outcome;
  final SaleOutageScope? scope;
  final int recoveredCount;
  final int failedCount;
}

typedef SaleOutageRecoveryNow = DateTime Function();
typedef SaleOutageRecoveryLoadOrders = Future<void> Function({DateTime? date});
typedef SaleOutageRecoveryReadOrders = List<Order> Function();
typedef SaleOutageRecoverySubmitClaim = Future<void> Function(Order order);

final saleOutageRecoveryNowProvider = Provider<SaleOutageRecoveryNow>((ref) {
  return DateTime.now;
});

final saleOutageRecoveryCooldownProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

final saleOutageRecoveryControllerProvider =
    Provider<SaleOutageRecoveryController>((ref) {
      return SaleOutageRecoveryController(
        readScope: () => ref.read(saleOutageScopeProvider),
        readConnectivity: () => ref.read(appConnectivityStatusProvider),
        loadOrders: ({DateTime? date}) =>
            ref.read(ordersProvider.notifier).load(date: date),
        readOrders: () => ref.read(ordersProvider),
        submitManualClaim: (order) => ref
            .read(ordersProvider.notifier)
            .submitManualExternalPaymentClaim(order),
        now: ref.read(saleOutageRecoveryNowProvider),
        cooldown: ref.read(saleOutageRecoveryCooldownProvider),
      );
    });

class SaleOutageRecoveryController {
  SaleOutageRecoveryController({
    required SaleOutageScope? Function() readScope,
    required AppConnectivityStatus Function() readConnectivity,
    required SaleOutageRecoveryLoadOrders loadOrders,
    required SaleOutageRecoveryReadOrders readOrders,
    required SaleOutageRecoverySubmitClaim submitManualClaim,
    required SaleOutageRecoveryNow now,
    required Duration cooldown,
  }) : _readScope = readScope,
       _readConnectivity = readConnectivity,
       _loadOrders = loadOrders,
       _readOrders = readOrders,
       _submitManualClaim = submitManualClaim,
       _now = now,
       _cooldown = cooldown;

  final SaleOutageScope? Function() _readScope;
  final AppConnectivityStatus Function() _readConnectivity;
  final SaleOutageRecoveryLoadOrders _loadOrders;
  final SaleOutageRecoveryReadOrders _readOrders;
  final SaleOutageRecoverySubmitClaim _submitManualClaim;
  final SaleOutageRecoveryNow _now;
  final Duration _cooldown;

  final Set<String> _inFlightKeys = <String>{};
  final Map<String, DateTime> _lastCompletedAtByKey = <String, DateTime>{};

  Future<SaleOutageRecoveryResult> recoverBranchWorkspace({
    required SaleOutageRecoveryTrigger trigger,
    SaleOutageScope? scopeOverride,
    bool bypassCooldown = false,
  }) async {
    final scope = scopeOverride ?? _readScope();
    if (scope == null) {
      return SaleOutageRecoveryResult(
        trigger: trigger,
        outcome: SaleOutageRecoveryOutcome.skippedNoScope,
      );
    }

    if (_readConnectivity() != AppConnectivityStatus.online) {
      return SaleOutageRecoveryResult(
        trigger: trigger,
        outcome: SaleOutageRecoveryOutcome.skippedOffline,
        scope: scope,
      );
    }

    final runKey = _buildRunKey(scope);
    if (_inFlightKeys.contains(runKey)) {
      return SaleOutageRecoveryResult(
        trigger: trigger,
        outcome: SaleOutageRecoveryOutcome.skippedInFlight,
        scope: scope,
      );
    }

    final currentTime = _now();
    final lastCompletedAt = _lastCompletedAtByKey[runKey];
    if (!bypassCooldown &&
        lastCompletedAt != null &&
        currentTime.difference(lastCompletedAt) < _cooldown) {
      return SaleOutageRecoveryResult(
        trigger: trigger,
        outcome: SaleOutageRecoveryOutcome.skippedCooldown,
        scope: scope,
      );
    }

    _inFlightKeys.add(runKey);
    try {
      await _loadOrders(date: currentTime);
      final candidates = _readOrders()
          .where(_isEligibleRecordedManualClaim)
          .toList(growable: false);
      if (candidates.isEmpty) {
        _lastCompletedAtByKey[runKey] = _now();
        return SaleOutageRecoveryResult(
          trigger: trigger,
          outcome: SaleOutageRecoveryOutcome.noPending,
          scope: scope,
        );
      }

      var recoveredCount = 0;
      var failedCount = 0;
      for (final order in candidates) {
        try {
          await _submitManualClaim(order);
          recoveredCount += 1;
        } catch (_) {
          failedCount += 1;
        }
      }

      _lastCompletedAtByKey[runKey] = _now();
      return SaleOutageRecoveryResult(
        trigger: trigger,
        outcome: failedCount == 0
            ? SaleOutageRecoveryOutcome.success
            : SaleOutageRecoveryOutcome.partialFailure,
        scope: scope,
        recoveredCount: recoveredCount,
        failedCount: failedCount,
      );
    } finally {
      _inFlightKeys.remove(runKey);
    }
  }

  bool _isEligibleRecordedManualClaim(Order order) {
    return order.isManualClaimOutageOrder &&
        order.hasManualExternalPaymentClaimRecorded &&
        !order.hasSubmittedManualExternalPaymentClaim &&
        !order.hasRejectedManualExternalPaymentClaim;
  }

  String _buildRunKey(SaleOutageScope scope) {
    return [scope.tenantId, scope.branchId, scope.accountId].join('|');
  }
}
