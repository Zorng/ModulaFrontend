import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/features/staff/data/staff_shift_cache_store.dart';
import 'package:modular_pos/features/staff/data/staff_shift_sync_pull_consumer.dart';

void main() {
  late AppDatabase database;
  late DriftStaffShiftCacheStore cacheStore;
  late StaffShiftSyncPullConsumer consumer;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cacheStore = DriftStaffShiftCacheStore(database);
    consumer = StaffShiftSyncPullConsumer(cacheStore);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'apply writes tenant options and scoped schedule when range metadata exists',
    () async {
      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
        ),
        payload: const {
          'branches': [
            {
              'branchId': 'branch-1',
              'tenantId': 'tenant-1',
              'branchName': 'Main Branch',
              'status': 'ACTIVE',
            },
          ],
          'memberships': [
            {
              'membershipId': 'membership-1',
              'tenantId': 'tenant-1',
              'accountId': 'account-1',
              'roleKey': 'CASHIER',
              'membershipStatus': 'ACTIVE',
              'phone': '+85512345678',
              'firstName': 'John',
              'lastName': 'Smith',
              'pendingBranchIds': [],
              'activeBranchIds': ['branch-1'],
            },
          ],
          'fromDate': '2026-03-17',
          'toDate': '2026-03-23',
          'membershipId': 'membership-1',
          'patterns': [
            {
              'id': 'pattern-1',
              'tenantId': 'tenant-1',
              'membershipId': 'membership-1',
              'branchId': 'branch-1',
              'daysOfWeek': [1, 3, 5],
              'plannedStartTime': '08:00',
              'plannedEndTime': '17:00',
              'status': 'ACTIVE',
              'createdAt': '2026-03-01T00:00:00Z',
              'updatedAt': '2026-03-01T00:00:00Z',
            },
          ],
          'instances': [
            {
              'id': 'instance-1',
              'tenantId': 'tenant-1',
              'membershipId': 'membership-1',
              'branchId': 'branch-1',
              'patternId': 'pattern-1',
              'date': '2026-03-18T00:00:00Z',
              'plannedStartTime': '08:00',
              'plannedEndTime': '17:00',
              'status': 'PLANNED',
              'createdAt': '2026-03-01T00:00:00Z',
              'updatedAt': '2026-03-01T00:00:00Z',
            },
          ],
        },
        cursor: 'cursor-1',
        pulledAt: DateTime.utc(2026, 3, 17, 20),
      );

      final cached = await cacheStore.read(
        tenantId: 'tenant-1',
        scope: const StaffShiftCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          membershipId: 'membership-1',
          fromDate: '2026-03-17',
          toDate: '2026-03-23',
        ),
      );

      expect(cached.branches.single.branchName, 'Main Branch');
      expect(cached.memberships.single.displayName, 'John Smith');
      expect(cached.schedule.patterns.single.id, 'pattern-1');
      expect(cached.schedule.instances.single.id, 'instance-1');
    },
  );

  test(
    'apply writes options without inventing schedule scope when range is missing',
    () async {
      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
        ),
        payload: const {
          'branches': [
            {
              'branchId': 'branch-1',
              'tenantId': 'tenant-1',
              'branchName': 'Main Branch',
              'status': 'ACTIVE',
            },
          ],
          'patterns': [
            {
              'id': 'pattern-1',
              'tenantId': 'tenant-1',
              'membershipId': 'membership-1',
              'branchId': 'branch-1',
              'daysOfWeek': [1],
              'plannedStartTime': '08:00',
              'plannedEndTime': '17:00',
              'status': 'ACTIVE',
              'createdAt': '2026-03-01T00:00:00Z',
              'updatedAt': '2026-03-01T00:00:00Z',
            },
          ],
        },
        cursor: 'cursor-2',
        pulledAt: DateTime.utc(2026, 3, 17, 21),
      );

      final bootstrap = await cacheStore.read(tenantId: 'tenant-1');
      final scoped = await cacheStore.read(
        tenantId: 'tenant-1',
        scope: const StaffShiftCacheScope(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          fromDate: '2026-03-17',
          toDate: '2026-03-23',
        ),
      );

      expect(bootstrap.branches.single.branchName, 'Main Branch');
      expect(scoped.schedule.patterns, isEmpty);
      expect(scoped.schedule.instances, isEmpty);
    },
  );

  test('apply can update tenant options without branch context', () async {
    await consumer.apply(
      context: const SyncPullContext(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: '',
        accountId: 'account-1',
      ),
      payload: const {
        'memberships': [
          {
            'membershipId': 'membership-1',
            'tenantId': 'tenant-1',
            'accountId': 'account-1',
            'roleKey': 'CASHIER',
            'membershipStatus': 'ACTIVE',
            'phone': '+85512345678',
            'firstName': 'John',
            'lastName': 'Smith',
            'pendingBranchIds': [],
            'activeBranchIds': ['branch-1'],
          },
        ],
      },
      cursor: 'cursor-3',
      pulledAt: DateTime.utc(2026, 3, 17, 22),
    );

    final bootstrap = await cacheStore.read(tenantId: 'tenant-1');

    expect(bootstrap.memberships.single.membershipId, 'membership-1');
  });
}
