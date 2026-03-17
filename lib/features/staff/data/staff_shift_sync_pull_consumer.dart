import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/features/staff/data/dto/staff_membership_dto.dart';
import 'package:modular_pos/features/staff/data/dto/staff_shift_dto.dart';
import 'package:modular_pos/features/staff/data/staff_shift_cache_store.dart';
import 'package:modular_pos/features/staff/data/staff_shift_mapper.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

final staffShiftSyncPullConsumerProvider = Provider<SyncPullConsumer>((ref) {
  final cacheStore = ref.watch(staffShiftCacheStoreProvider);
  return StaffShiftSyncPullConsumer(cacheStore);
});

class StaffShiftSyncPullConsumer implements SyncPullConsumer {
  StaffShiftSyncPullConsumer(this._cacheStore);

  final StaffShiftCacheStore _cacheStore;

  static const _bundleKeys = <String>['shift', 'schedule', 'data', 'snapshot'];
  static const _branchesKeys = <String>['branches', 'availableBranches'];
  static const _membershipsKeys = <String>['memberships', 'staffMemberships'];
  static const _patternsKeys = <String>['patterns', 'shiftPatterns'];
  static const _instancesKeys = <String>['instances', 'shiftInstances'];
  static const _fromKeys = <String>['fromDate', 'from', 'startDate'];
  static const _toKeys = <String>['toDate', 'to', 'endDate'];

  @override
  SyncModuleScope get scope => SyncModuleScope.shift;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required dynamic payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    final bundle = _extractBundle(payload);
    if (!_looksLikeBundle(bundle)) return;

    final tenantId = context.tenantId.trim();
    final branchId = context.branchId.trim();
    if (tenantId.isEmpty) {
      throw StateError('Shift sync pull requires tenant context.');
    }

    final hasBranches = _containsList(bundle, _branchesKeys);
    final hasMemberships = _containsList(bundle, _membershipsKeys);
    if (hasBranches || hasMemberships) {
      final existing = await _cacheStore.read(tenantId: tenantId);
      final branches = hasBranches
          ? _extractList(bundle, _branchesKeys)
                .map((entry) => ApiContract.asJsonMap(entry))
                .where((entry) => entry.isNotEmpty)
                .map(
                  (entry) =>
                      mapShiftBranchData(entry, tenantIdFallback: tenantId),
                )
                .toList(growable: false)
          : existing.branches;
      final memberships = hasMemberships
          ? _extractList(bundle, _membershipsKeys)
                .map((entry) => ApiContract.asJsonMap(entry))
                .where((entry) => entry.isNotEmpty)
                .map(StaffMembershipDto.fromJson)
                .map(mapStaffMembershipDto)
                .toList(growable: false)
          : existing.memberships;
      await _cacheStore.writeOptions(
        tenantId: tenantId,
        branches: branches,
        memberships: memberships,
      );
    }

    if (branchId.isEmpty) return;

    final hasPatterns = _containsList(bundle, _patternsKeys);
    final hasInstances = _containsList(bundle, _instancesKeys);
    if (!hasPatterns && !hasInstances) return;

    final fromDate = _readString(bundle, _fromKeys);
    final toDate = _readString(bundle, _toKeys);
    if (fromDate == null || toDate == null) return;

    final membershipId = (_readString(bundle, const ['membershipId']) ?? '')
        .trim();

    final List<StaffShiftPattern> patterns = hasPatterns
        ? _extractList(bundle, _patternsKeys)
              .map((entry) => ApiContract.asJsonMap(entry))
              .where((entry) => entry.isNotEmpty)
              .map(StaffShiftPatternDto.fromJson)
              .map(mapStaffShiftPatternDto)
              .toList(growable: false)
        : const <StaffShiftPattern>[];
    final List<StaffShiftInstance> instances = hasInstances
        ? _extractList(bundle, _instancesKeys)
              .map((entry) => ApiContract.asJsonMap(entry))
              .where((entry) => entry.isNotEmpty)
              .map(StaffShiftInstanceDto.fromJson)
              .map(mapStaffShiftInstanceDto)
              .toList(growable: false)
        : const <StaffShiftInstance>[];

    await _cacheStore.writeSchedule(
      scope: StaffShiftCacheScope(
        tenantId: tenantId,
        branchId: branchId,
        fromDate: fromDate,
        toDate: toDate,
        membershipId: membershipId.isEmpty ? null : membershipId,
      ),
      schedule: StaffShiftSchedule(
        membershipId: membershipId.isEmpty ? null : membershipId,
        patterns: patterns,
        instances: instances,
      ),
    );
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
    return _branchesKeys.any(value.containsKey) ||
        _membershipsKeys.any(value.containsKey) ||
        _patternsKeys.any(value.containsKey) ||
        _instancesKeys.any(value.containsKey);
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

  String? _readString(Map<String, dynamic> bundle, List<String> keys) {
    for (final key in keys) {
      final raw = bundle[key]?.toString().trim() ?? '';
      if (raw.isNotEmpty) return raw;
    }
    return null;
  }
}
