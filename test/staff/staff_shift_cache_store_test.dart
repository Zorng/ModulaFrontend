import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/staff_shift_cache_store.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

void main() {
  late AppDatabase database;
  late StaffShiftCacheStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftStaffShiftCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes and reads cached shift options and schedule by scope', () async {
    const tenantId = 'tenant-1';
    const scope = StaffShiftCacheScope(
      tenantId: tenantId,
      branchId: 'branch-1',
      membershipId: 'membership-1',
      fromDate: '2026-03-17',
      toDate: '2026-03-23',
    );

    await store.writeOptions(
      tenantId: tenantId,
      branches: const [
        BranchListItem(
          branchId: 'branch-1',
          tenantId: tenantId,
          branchName: 'Main Branch',
          status: 'ACTIVE',
        ),
      ],
      memberships: const [
        StaffMembershipSummary(
          membershipId: 'membership-1',
          tenantId: tenantId,
          accountId: 'account-1',
          roleKey: 'CASHIER',
          membershipStatus: MembershipLifecycleStatus.active,
          phone: '+85512345678',
          firstName: 'John',
          lastName: 'Smith',
          staffProfileStatus: 'ACTIVE',
          invitedAt: null,
          acceptedAt: null,
          rejectedAt: null,
          revokedAt: null,
          pendingBranchIds: <String>[],
          activeBranchIds: <String>['branch-1'],
        ),
      ],
    );
    await store.writeSchedule(
      scope: scope,
      schedule: StaffShiftSchedule(
        membershipId: 'membership-1',
        patterns: [
          StaffShiftPattern(
            id: 'pattern-1',
            tenantId: tenantId,
            membershipId: 'membership-1',
            branchId: 'branch-1',
            daysOfWeek: const [1, 3, 5],
            plannedStartTime: '08:00',
            plannedEndTime: '17:00',
            status: StaffShiftPatternStatus.active,
            effectiveFrom: DateTime.utc(2026, 3, 1),
            effectiveTo: null,
            note: 'Weekday',
            createdAt: DateTime.utc(2026, 3, 1),
            updatedAt: DateTime.utc(2026, 3, 2),
          ),
        ],
        instances: [
          StaffShiftInstance(
            id: 'instance-1',
            tenantId: tenantId,
            membershipId: 'membership-1',
            branchId: 'branch-1',
            patternId: 'pattern-1',
            date: DateTime.utc(2026, 3, 18),
            plannedStartTime: '08:00',
            plannedEndTime: '17:00',
            status: StaffShiftInstanceStatus.planned,
            note: 'Manual override',
            createdAt: DateTime.utc(2026, 3, 2),
            updatedAt: DateTime.utc(2026, 3, 2),
          ),
        ],
      ),
    );

    final cached = await store.read(tenantId: tenantId, scope: scope);

    expect(cached.branches.single.branchName, 'Main Branch');
    expect(cached.memberships.single.displayName, 'John Smith');
    expect(cached.schedule.patterns.single.id, 'pattern-1');
    expect(cached.schedule.patterns.single.daysOfWeek, [1, 3, 5]);
    expect(cached.schedule.instances.single.id, 'instance-1');
    expect(cached.schedule.membershipId, 'membership-1');
  });

  test('clearTenant removes cached options and schedules for tenant', () async {
    await store.writeOptions(
      tenantId: 'tenant-1',
      branches: const [
        BranchListItem(
          branchId: 'branch-1',
          tenantId: 'tenant-1',
          branchName: 'Main Branch',
          status: 'ACTIVE',
        ),
      ],
      memberships: const [],
    );
    await store.writeSchedule(
      scope: const StaffShiftCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        fromDate: '2026-03-17',
        toDate: '2026-03-23',
      ),
      schedule: const StaffShiftSchedule(patterns: [], instances: []),
    );

    await store.clearTenant(tenantId: 'tenant-1');

    final cached = await store.read(
      tenantId: 'tenant-1',
      scope: const StaffShiftCacheScope(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        fromDate: '2026-03-17',
        toDate: '2026-03-23',
      ),
    );

    expect(cached.branches, isEmpty);
    expect(cached.memberships, isEmpty);
    expect(cached.schedule.patterns, isEmpty);
    expect(cached.schedule.instances, isEmpty);
  });
}
