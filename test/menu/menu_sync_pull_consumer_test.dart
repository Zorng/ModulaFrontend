import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/features/menu/data/menu_cache_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/data/menu_sync_pull_consumer.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

final _sqliteAvailable = () {
  try {
    final db = sqlite3.sqlite3.openInMemory();
    db.dispose();
    return true;
  } catch (_) {
    return false;
  }
}();

void main() {
  group('MenuSyncPullConsumer', () {
    late AppDatabase database;
    late DriftMenuCacheStore cacheStore;
    late MenuSyncPullConsumer consumer;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      cacheStore = DriftMenuCacheStore(database);
      consumer = MenuSyncPullConsumer(cacheStore);
    });

    tearDown(() async {
      await database.close();
    });

    test('apply writes branch-context menu bundle for active branch', () async {
      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
        ),
        payload: const {
          'items': [
            {
              'id': 'item-1',
              'tenantId': 'tenant-1',
              'name': 'Latte',
              'categoryId': 'cat-1',
              'basePrice': 2.5,
              'modifierGroupIds': ['group-1'],
            },
          ],
          'categories': [
            {'id': 'cat-1', 'tenantId': 'tenant-1', 'name': 'Coffee'},
          ],
          'modifierGroups': [
            {
              'id': 'group-1',
              'tenantId': 'tenant-1',
              'name': 'Milk',
              'selectionMode': 'SINGLE',
              'pricingBehavior': 'addon',
              'options': [],
            },
          ],
          'branches': [
            {'id': 'branch-1', 'name': 'Branch 1'},
          ],
        },
        cursor: 'cursor-1',
        pulledAt: DateTime.utc(2026, 3, 17, 14),
      );

      final scope = MenuCacheQuery(
        tenantId: 'tenant-1',
        scopeKey: buildMenuCacheScopeKey(
          readLane: MenuReadLane.branchContext,
          status: 'active',
          branchIdFilter: 'branch-1',
        ),
        readLane: MenuReadLane.branchContext,
        status: 'active',
        branchIdFilter: 'branch-1',
      );
      final cached = await cacheStore.read(scope);

      expect(cached, isNotNull);
      expect(cached!.items.single.id, 'item-1');
      expect(cached.categories.single.id, 'cat-1');
      expect(cached.modifierGroups.single.id, 'group-1');
      expect(cached.branches.single.id, 'branch-1');
    });

    test('apply preserves existing lists when pull payload is partial', () async {
      const scope = MenuCacheQuery(
        tenantId: 'tenant-1',
        scopeKey: 'branchContext|active|branch-1',
        readLane: MenuReadLane.branchContext,
        status: 'active',
        branchIdFilter: 'branch-1',
      );
      await cacheStore.write(
        scope: scope,
        bundle: const MenuDataBundle(
          items: [
            MenuItem(
              id: 'item-1',
              name: 'Latte',
              categoryId: 'cat-1',
              price: 2.5,
            ),
          ],
          categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
          modifierGroups: [
            ModifierGroup(
              id: 'group-1',
              name: 'Milk',
              selectionType: 'single',
              pricingBehavior: 'addon',
              options: [],
            ),
          ],
          branches: [MenuBranch(id: 'branch-1', name: 'Branch 1')],
        ),
      );

      await consumer.apply(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
        ),
        payload: const {
          'items': [
            {
              'id': 'item-2',
              'tenantId': 'tenant-1',
              'name': 'Mocha',
              'categoryId': 'cat-2',
              'basePrice': 3.0,
            },
          ],
        },
        cursor: 'cursor-2',
        pulledAt: DateTime.utc(2026, 3, 17, 15),
      );

      final cached = await cacheStore.read(scope);

      expect(cached, isNotNull);
      expect(cached!.items.single.id, 'item-2');
      expect(cached.categories.single.id, 'cat-1');
      expect(cached.modifierGroups.single.id, 'group-1');
      expect(cached.branches.single.id, 'branch-1');
    });

    test('apply requires branch context', () async {
      await expectLater(
        () => consumer.apply(
          context: const SyncPullContext(
            deviceId: 'device-1',
            tenantId: 'tenant-1',
            branchId: '',
          ),
          payload: const {'items': []},
          cursor: 'cursor-3',
          pulledAt: DateTime.utc(2026, 3, 17, 16),
        ),
        throwsA(isA<StateError>()),
      );
    });
  }, skip: _sqliteAvailable ? false : 'sqlite3.dll not available for Drift tests on this machine');
}
