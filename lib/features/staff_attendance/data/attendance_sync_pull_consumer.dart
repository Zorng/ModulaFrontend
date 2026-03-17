import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_mapper.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';

final attendanceSyncPullConsumerProvider = Provider<SyncPullConsumer>((ref) {
  final cacheStore = ref.watch(attendanceCacheStoreProvider);
  return AttendanceSyncPullConsumer(cacheStore);
});

class AttendanceSyncPullConsumer implements SyncPullConsumer {
  AttendanceSyncPullConsumer(this._cacheStore);

  final AttendanceCacheStore _cacheStore;

  static const _bundleKeys = <String>[
    'attendance',
    'attendanceState',
    'snapshot',
    'data',
  ];
  static const _contextKeys = <String>[
    'context',
    'attendanceContext',
    'checkContext',
  ];
  static const _recordKeys = <String>[
    'records',
    'attendanceRecords',
    'history',
  ];

  @override
  SyncModuleScope get scope => SyncModuleScope.attendance;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required dynamic payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    final branchId = context.branchId.trim();
    final accountId = context.accountId.trim();
    if (branchId.isEmpty || accountId.isEmpty) {
      throw StateError(
        'Attendance sync pull requires branch and account context.',
      );
    }

    final scope = AttendanceCacheScope(
      tenantId: context.tenantId.trim(),
      branchId: branchId,
      accountId: accountId,
    );
    final bundle = _extractBundle(payload);
    if (!_looksLikeBundle(bundle)) return;

    final existing = await _cacheStore.read(scope);

    final contextPayloadExists = _containsContext(bundle);
    final recordListExists = _containsList(bundle, _recordKeys);

    if (contextPayloadExists) {
      final contextMap = _extractContextMap(bundle);
      final nextContext = contextMap == null
          ? const AttendanceContext.empty()
          : mapAttendanceContextData(contextMap);
      await _cacheStore.writeContext(scope: scope, context: nextContext);
    }

    if (recordListExists) {
      final records = _extractList(bundle, _recordKeys)
          .map((entry) => ApiContract.asJsonMap(entry))
          .where((entry) => entry.isNotEmpty)
          .map(mapAttendanceRecordData)
          .toList(growable: false);
      await _cacheStore.writeRecords(scope: scope, records: records);
    } else if (!contextPayloadExists &&
        existing.context == null &&
        existing.records.isEmpty) {
      return;
    }
  }

  Map<String, dynamic> _extractBundle(dynamic payload) {
    final root = ApiContract.asJsonMap(payload);
    if (_looksLikeBundle(root)) return root;

    for (final key in _bundleKeys) {
      final candidate = ApiContract.asJsonMap(root[key]);
      if (_looksLikeBundle(candidate)) {
        return candidate;
      }
    }

    return root;
  }

  bool _looksLikeBundle(Map<String, dynamic> value) {
    if (value.isEmpty) return false;
    return _contextKeys.any(value.containsKey) ||
        _recordKeys.any(value.containsKey);
  }

  bool _containsContext(Map<String, dynamic> bundle) {
    return _contextKeys.any(bundle.containsKey);
  }

  Map<String, dynamic>? _extractContextMap(Map<String, dynamic> bundle) {
    for (final key in _contextKeys) {
      if (!bundle.containsKey(key)) continue;
      final candidate = bundle[key];
      if (candidate == null) return null;
      final parsed = ApiContract.asJsonMap(candidate);
      if (parsed.isNotEmpty) return parsed;
      return null;
    }
    return null;
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
}
