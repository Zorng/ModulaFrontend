import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_cache_store.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_mapper.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_movement_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_sale_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

final cashSessionSyncPullConsumerProvider = Provider<SyncPullConsumer>((ref) {
  final cacheStore = ref.watch(cashSessionCacheStoreProvider);
  return CashSessionSyncPullConsumer(cacheStore);
});

class CashSessionSyncPullConsumer implements SyncPullConsumer {
  CashSessionSyncPullConsumer(this._cacheStore);

  final CashSessionCacheStore _cacheStore;

  static const _bundleKeys = <String>[
    'snapshot',
    'cashSession',
    'activeSession',
    'sessionState',
    'data',
  ];
  static const _sessionKeys = <String>[
    'session',
    'cashSession',
    'activeSession',
    'currentSession',
  ];
  static const _movementKeys = <String>[
    'movements',
    'movementRecords',
    'activity',
  ];
  static const _salesKeys = <String>['sales', 'sessionSales', 'saleOrders'];

  @override
  SyncModuleScope get scope => SyncModuleScope.cashSession;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required dynamic payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    final bundle = _extractBundle(payload);
    if (bundle.isEmpty) return;

    if (_isExplicitNoActiveSession(bundle)) {
      await _cacheStore.clear(
        tenantId: context.tenantId,
        branchId: context.branchId,
      );
      return;
    }

    final sessionMap = _extractSessionMap(bundle);
    if (sessionMap.isEmpty) return;

    final session = mapCashSessionDto(
      CashSessionDto.fromJson(sessionMap),
      tenantIdFallback: context.tenantId,
      branchIdFallback: context.branchId,
    );

    if (session.tenantId.trim().isEmpty || session.branchId.trim().isEmpty) {
      throw StateError(
        'Cash session sync payload is missing tenant or branch context.',
      );
    }

    final existingSnapshot = await _cacheStore.read(
      tenantId: context.tenantId,
      branchId: context.branchId,
    );
    final hasMovementList = _containsList(bundle, _movementKeys);
    final hasSalesList = _containsList(bundle, _salesKeys);

    final movements = hasMovementList
        ? _extractList(bundle, _movementKeys)
              .map((item) => ApiContract.asJsonMap(item))
              .where((item) => item.isNotEmpty)
              .map(CashMovementDto.fromJson)
              .map(mapCashMovementDto)
              .toList(growable: false)
        : _preserveExistingMovements(existingSnapshot, session.id);

    final sales = hasSalesList
        ? _extractList(bundle, _salesKeys)
              .map((item) => ApiContract.asJsonMap(item))
              .where((item) => item.isNotEmpty)
              .map(CashSessionSaleDto.fromJson)
              .map(mapCashSessionSaleDto)
              .toList(growable: false)
        : _preserveExistingSales(existingSnapshot, session.id);

    await _cacheStore.write(
      tenantId: context.tenantId,
      branchId: context.branchId,
      session: session,
      movements: movements,
      sales: sales,
    );
  }

  Map<String, dynamic> _extractBundle(dynamic payload) {
    final root = ApiContract.asJsonMap(payload);
    if (_looksLikeBundle(root) || _looksLikeSession(root)) return root;

    for (final key in _bundleKeys) {
      final candidate = ApiContract.asJsonMap(root[key]);
      if (_looksLikeBundle(candidate) || _looksLikeSession(candidate)) {
        return candidate;
      }
    }

    return root;
  }

  bool _looksLikeBundle(Map<String, dynamic> value) {
    if (value.isEmpty) return false;
    return _sessionKeys.any(value.containsKey) ||
        _movementKeys.any(value.containsKey) ||
        _salesKeys.any(value.containsKey) ||
        value.containsKey('hasActiveSession');
  }

  bool _looksLikeSession(Map<String, dynamic> value) {
    if (value.isEmpty) return false;
    return value.containsKey('id') &&
        (value.containsKey('status') ||
            value.containsKey('openedByAccountId') ||
            value.containsKey('openingFloatUsd'));
  }

  bool _isExplicitNoActiveSession(Map<String, dynamic> bundle) {
    if (bundle['hasActiveSession'] == false) return true;
    for (final key in _sessionKeys) {
      if (bundle.containsKey(key) && bundle[key] == null) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _extractSessionMap(Map<String, dynamic> bundle) {
    if (_looksLikeSession(bundle)) return bundle;
    for (final key in _sessionKeys) {
      final candidate = ApiContract.asJsonMap(bundle[key]);
      if (_looksLikeSession(candidate)) {
        return candidate;
      }
    }
    return const <String, dynamic>{};
  }

  bool _containsList(Map<String, dynamic> bundle, List<String> keys) {
    for (final key in keys) {
      if (bundle[key] is List) return true;
    }
    return false;
  }

  List<dynamic> _extractList(Map<String, dynamic> bundle, List<String> keys) {
    for (final key in keys) {
      final value = bundle[key];
      if (value is List) return value;
    }
    return const <dynamic>[];
  }

  List<CashMovement> _preserveExistingMovements(
    CashSessionCacheSnapshot snapshot,
    String sessionId,
  ) {
    if (snapshot.session?.id != sessionId) return const <CashMovement>[];
    return snapshot.movements;
  }

  List<CashSessionSale> _preserveExistingSales(
    CashSessionCacheSnapshot snapshot,
    String sessionId,
  ) {
    if (snapshot.session?.id != sessionId) return const <CashSessionSale>[];
    return snapshot.sales;
  }
}
