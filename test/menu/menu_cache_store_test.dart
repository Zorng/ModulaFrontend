import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/menu/data/menu_cache_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

void main() {
  late AppDatabase database;
  late MenuCacheStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftMenuCacheStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes and reads menu bundle by tenant scope', () async {
    const scope = MenuCacheQuery(
      tenantId: 'tenant-1',
      scopeKey: 'management|active|all',
      readLane: MenuReadLane.management,
      status: 'active',
    );

    await store.write(
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

    final cached = await store.read(scope);

    expect(cached, isNotNull);
    expect(cached!.items.single.id, 'item-1');
    expect(cached.categories.single.id, 'cat-1');
    expect(cached.modifierGroups.single.id, 'group-1');
    expect(cached.branches.single.id, 'branch-1');
  });

  test('clear removes only the targeted menu scope', () async {
    const scopeA = MenuCacheQuery(
      tenantId: 'tenant-1',
      scopeKey: 'management|active|all',
      readLane: MenuReadLane.management,
      status: 'active',
    );
    const scopeB = MenuCacheQuery(
      tenantId: 'tenant-1',
      scopeKey: 'branchContext|active|branch-1',
      readLane: MenuReadLane.branchContext,
      status: 'active',
      branchIdFilter: 'branch-1',
    );

    await store.write(
      scope: scopeA,
      bundle: const MenuDataBundle(
        items: [
          MenuItem(
            id: 'item-1',
            name: 'Latte',
            categoryId: 'cat-1',
            price: 2.5,
          ),
        ],
        categories: [],
        modifierGroups: [],
        branches: [],
      ),
    );
    await store.write(
      scope: scopeB,
      bundle: const MenuDataBundle(
        items: [
          MenuItem(id: 'item-2', name: 'Mocha', categoryId: 'cat-2', price: 3),
        ],
        categories: [],
        modifierGroups: [],
        branches: [],
      ),
    );

    await store.clear(scopeA);

    final cleared = await store.read(scopeA);
    final remaining = await store.read(scopeB);

    expect(cleared, isNull);
    expect(remaining?.items.single.id, 'item-2');
  });
}
