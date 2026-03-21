import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

class StaffShiftCacheScope {
  const StaffShiftCacheScope({
    required this.tenantId,
    required this.branchId,
    required this.fromDate,
    required this.toDate,
    this.membershipId,
  });

  final String tenantId;
  final String branchId;
  final String fromDate;
  final String toDate;
  final String? membershipId;

  String get scopeKey => buildStaffShiftCacheScopeKey(
    branchId: branchId,
    fromDate: fromDate,
    toDate: toDate,
    membershipId: membershipId,
  );
}

String buildStaffShiftCacheScopeKey({
  required String branchId,
  required String fromDate,
  required String toDate,
  String? membershipId,
}) {
  final normalizedBranchId = branchId.trim();
  final normalizedMembershipId = (membershipId ?? '').trim();
  final membershipKey = normalizedMembershipId.isEmpty
      ? 'all'
      : normalizedMembershipId;
  return '$normalizedBranchId|$membershipKey|${fromDate.trim()}|${toDate.trim()}';
}

class StaffShiftCacheSnapshot {
  const StaffShiftCacheSnapshot({
    required this.branches,
    required this.memberships,
    required this.schedule,
  });

  final List<BranchListItem> branches;
  final List<StaffMembershipSummary> memberships;
  final StaffShiftSchedule schedule;

  bool get hasAnyData =>
      branches.isNotEmpty ||
      memberships.isNotEmpty ||
      schedule.patterns.isNotEmpty ||
      schedule.instances.isNotEmpty;
}

abstract class StaffShiftCacheStore {
  Future<StaffShiftCacheSnapshot> read({
    required String tenantId,
    StaffShiftCacheScope? scope,
  });

  Future<void> writeOptions({
    required String tenantId,
    required List<BranchListItem> branches,
    required List<StaffMembershipSummary> memberships,
  });

  Future<void> writeSchedule({
    required StaffShiftCacheScope scope,
    required StaffShiftSchedule schedule,
  });

  Future<void> clearTenant({required String tenantId});
}

class DriftStaffShiftCacheStore implements StaffShiftCacheStore {
  DriftStaffShiftCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<StaffShiftCacheSnapshot> read({
    required String tenantId,
    StaffShiftCacheScope? scope,
  }) async {
    final normalizedTenantId = tenantId.trim();
    final branchRows =
        await (_db.select(_db.staffShiftBranchCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
    final membershipRows =
        await (_db.select(_db.staffShiftMembershipCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();

    final branches = branchRows
        .map(
          (row) => BranchListItem(
            branchId: row.branchId,
            tenantId: row.tenantId,
            branchName: row.branchName,
            status: row.status,
          ),
        )
        .toList(growable: false);
    final memberships = membershipRows
        .map(
          (row) => StaffMembershipSummary(
            membershipId: row.membershipId,
            tenantId: row.tenantId,
            accountId: row.accountId,
            roleKey: row.roleKey,
            membershipStatus: parseMembershipLifecycleStatus(
              row.membershipStatus,
            ),
            phone: row.phone,
            firstName: row.firstName,
            lastName: row.lastName,
            staffProfileStatus: row.staffProfileStatus,
            invitedAt: row.invitedAt,
            acceptedAt: row.acceptedAt,
            rejectedAt: row.rejectedAt,
            revokedAt: row.revokedAt,
            pendingBranchIds: _decodeStringList(row.pendingBranchIdsJson),
            activeBranchIds: _decodeStringList(row.activeBranchIdsJson),
          ),
        )
        .toList(growable: false);

    final schedule = scope == null
        ? StaffShiftSchedule(patterns: [], instances: [])
        : await _readSchedule(scope);

    return StaffShiftCacheSnapshot(
      branches: branches,
      memberships: memberships,
      schedule: schedule,
    );
  }

  @override
  Future<void> writeOptions({
    required String tenantId,
    required List<BranchListItem> branches,
    required List<StaffMembershipSummary> memberships,
  }) async {
    final normalizedTenantId = tenantId.trim();
    await _db.transaction(() async {
      await (_db.delete(
        _db.staffShiftBranchCacheEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();
      await (_db.delete(
        _db.staffShiftMembershipCacheEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();

      for (var index = 0; index < branches.length; index++) {
        final branch = branches[index];
        await _db
            .into(_db.staffShiftBranchCacheEntries)
            .insert(
              StaffShiftBranchCacheEntriesCompanion.insert(
                tenantId: normalizedTenantId,
                branchId: branch.branchId,
                sortOrder: index,
                branchName: branch.branchName,
                status: branch.status,
              ),
            );
      }

      for (var index = 0; index < memberships.length; index++) {
        final membership = memberships[index];
        await _db
            .into(_db.staffShiftMembershipCacheEntries)
            .insert(
              StaffShiftMembershipCacheEntriesCompanion.insert(
                tenantId: normalizedTenantId,
                membershipId: membership.membershipId,
                sortOrder: index,
                accountId: membership.accountId,
                roleKey: membership.roleKey,
                membershipStatus: membership.membershipStatus.name,
                phone: membership.phone,
                firstName: Value(membership.firstName),
                lastName: Value(membership.lastName),
                staffProfileStatus: Value(membership.staffProfileStatus),
                invitedAt: Value(membership.invitedAt),
                acceptedAt: Value(membership.acceptedAt),
                rejectedAt: Value(membership.rejectedAt),
                revokedAt: Value(membership.revokedAt),
                pendingBranchIdsJson: jsonEncode(membership.pendingBranchIds),
                activeBranchIdsJson: jsonEncode(membership.activeBranchIds),
              ),
            );
      }
    });
  }

  @override
  Future<void> writeSchedule({
    required StaffShiftCacheScope scope,
    required StaffShiftSchedule schedule,
  }) async {
    final normalizedTenantId = scope.tenantId.trim();
    final normalizedBranchId = scope.branchId.trim();
    final normalizedMembershipId = (scope.membershipId ?? '').trim();
    final scopeKey = scope.scopeKey;

    await _db.transaction(() async {
      await _db
          .into(_db.staffShiftScopeEntries)
          .insertOnConflictUpdate(
            StaffShiftScopeEntriesCompanion.insert(
              tenantId: normalizedTenantId,
              scopeKey: scopeKey,
              branchId: normalizedBranchId,
              membershipId: Value(normalizedMembershipId),
              fromDate: scope.fromDate.trim(),
              toDate: scope.toDate.trim(),
              cachedAt: DateTime.now(),
            ),
          );

      await (_db.delete(_db.staffShiftPatternCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.scopeKey.equals(scopeKey)))
          .go();
      await (_db.delete(_db.staffShiftInstanceCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
            ..where((tbl) => tbl.scopeKey.equals(scopeKey)))
          .go();

      for (var index = 0; index < schedule.patterns.length; index++) {
        final pattern = schedule.patterns[index];
        await _db
            .into(_db.staffShiftPatternCacheEntries)
            .insert(
              StaffShiftPatternCacheEntriesCompanion.insert(
                tenantId: normalizedTenantId,
                scopeKey: scopeKey,
                patternId: pattern.id,
                sortOrder: index,
                membershipId: pattern.membershipId,
                branchId: pattern.branchId,
                daysOfWeekJson: jsonEncode(pattern.daysOfWeek),
                plannedStartTime: pattern.plannedStartTime,
                plannedEndTime: pattern.plannedEndTime,
                status: pattern.status.name,
                effectiveFrom: Value(pattern.effectiveFrom),
                effectiveTo: Value(pattern.effectiveTo),
                note: Value(pattern.note),
                createdAt: pattern.createdAt,
                updatedAt: pattern.updatedAt,
              ),
            );
      }

      for (var index = 0; index < schedule.instances.length; index++) {
        final instance = schedule.instances[index];
        await _db
            .into(_db.staffShiftInstanceCacheEntries)
            .insert(
              StaffShiftInstanceCacheEntriesCompanion.insert(
                tenantId: normalizedTenantId,
                scopeKey: scopeKey,
                instanceId: instance.id,
                sortOrder: index,
                membershipId: instance.membershipId,
                branchId: instance.branchId,
                patternId: Value(instance.patternId),
                date: instance.date,
                plannedStartTime: instance.plannedStartTime,
                plannedEndTime: instance.plannedEndTime,
                status: instance.status.name,
                note: Value(instance.note),
                createdAt: instance.createdAt,
                updatedAt: instance.updatedAt,
              ),
            );
      }
    });
  }

  @override
  Future<void> clearTenant({required String tenantId}) async {
    final normalizedTenantId = tenantId.trim();
    await _db.transaction(() async {
      await (_db.delete(
        _db.staffShiftScopeEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();
      await (_db.delete(
        _db.staffShiftBranchCacheEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();
      await (_db.delete(
        _db.staffShiftMembershipCacheEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();
      await (_db.delete(
        _db.staffShiftPatternCacheEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();
      await (_db.delete(
        _db.staffShiftInstanceCacheEntries,
      )..where((tbl) => tbl.tenantId.equals(normalizedTenantId))).go();
    });
  }

  Future<StaffShiftSchedule> _readSchedule(StaffShiftCacheScope scope) async {
    final normalizedTenantId = scope.tenantId.trim();
    final normalizedBranchId = scope.branchId.trim();
    final normalizedMembershipId = (scope.membershipId ?? '').trim();

    final exactScopeRow =
        await (_db.select(_db.staffShiftScopeEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
            .getSingleOrNull();
    final resolvedScopeRow =
        exactScopeRow ??
        await (_db.select(_db.staffShiftScopeEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.branchId.equals(normalizedBranchId))
              ..where((tbl) => tbl.membershipId.equals(normalizedMembershipId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.cachedAt)]))
            .getSingleOrNull();

    if (resolvedScopeRow == null) {
      return StaffShiftSchedule(patterns: [], instances: []);
    }

    final patternRows =
        await (_db.select(_db.staffShiftPatternCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.scopeKey.equals(resolvedScopeRow.scopeKey))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
    final instanceRows =
        await (_db.select(_db.staffShiftInstanceCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(normalizedTenantId))
              ..where((tbl) => tbl.scopeKey.equals(resolvedScopeRow.scopeKey))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();

    return StaffShiftSchedule(
      membershipId: resolvedScopeRow.membershipId.trim().isEmpty
          ? null
          : resolvedScopeRow.membershipId,
      patterns: patternRows
          .map(
            (row) => StaffShiftPattern(
              id: row.patternId,
              tenantId: row.tenantId,
              membershipId: row.membershipId,
              branchId: row.branchId,
              daysOfWeek: _decodeIntList(row.daysOfWeekJson),
              plannedStartTime: row.plannedStartTime,
              plannedEndTime: row.plannedEndTime,
              status: parseStaffShiftPatternStatus(row.status),
              effectiveFrom: row.effectiveFrom,
              effectiveTo: row.effectiveTo,
              note: row.note,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false),
      instances: instanceRows
          .map(
            (row) => StaffShiftInstance(
              id: row.instanceId,
              tenantId: row.tenantId,
              membershipId: row.membershipId,
              branchId: row.branchId,
              patternId: row.patternId,
              date: row.date,
              plannedStartTime: row.plannedStartTime,
              plannedEndTime: row.plannedEndTime,
              status: parseStaffShiftInstanceStatus(row.status),
              note: row.note,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  List<String> _decodeStringList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <String>[];
    return decoded.map((entry) => entry.toString()).toList(growable: false);
  }

  List<int> _decodeIntList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <int>[];
    return decoded
        .map((entry) => int.tryParse(entry.toString()))
        .whereType<int>()
        .toList(growable: false);
  }
}

final staffShiftCacheStoreProvider = Provider<StaffShiftCacheStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftStaffShiftCacheStore(db);
});
