import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MenuCacheQuery {
  const MenuCacheQuery({
    required this.tenantId,
    required this.scopeKey,
    required this.readLane,
    required this.status,
    this.branchIdFilter,
  });

  final String tenantId;
  final String scopeKey;
  final MenuReadLane readLane;
  final String status;
  final String? branchIdFilter;
}

String buildMenuCacheScopeKey({
  required MenuReadLane readLane,
  required String status,
  String? branchIdFilter,
}) {
  final normalizedStatus = status.trim().isEmpty
      ? 'active'
      : status.trim().toLowerCase();
  final normalizedBranchId = (branchIdFilter ?? '').trim();
  final lane = readLane.name;
  final branch = normalizedBranchId.isEmpty ? 'all' : normalizedBranchId;
  return '$lane|$normalizedStatus|$branch';
}

abstract class MenuCacheStore {
  Future<MenuDataBundle?> read(MenuCacheQuery scope);

  Future<void> write({
    required MenuCacheQuery scope,
    required MenuDataBundle bundle,
  });

  Future<void> clear(MenuCacheQuery scope);
}

class DriftMenuCacheStore implements MenuCacheStore {
  DriftMenuCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<MenuDataBundle?> read(MenuCacheQuery scope) async {
    final scopeRow =
        await (_db.select(_db.menuCacheScopes)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
            .getSingleOrNull();
    if (scopeRow == null) return null;

    final itemRows =
        await (_db.select(_db.menuItemCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
    final categoryRows =
        await (_db.select(_db.menuCategoryCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
    final groupRows =
        await (_db.select(_db.menuModifierGroupCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();
    final branchRows =
        await (_db.select(_db.menuBranchCacheEntries)
              ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
              ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
            .get();

    return MenuDataBundle(
      items: itemRows
          .map(
            (row) => MenuItem.fromJson(
              jsonDecode(row.payloadJson) as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      categories: categoryRows
          .map(
            (row) => MenuCategory.fromJson(
              jsonDecode(row.payloadJson) as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      modifierGroups: groupRows
          .map(
            (row) => ModifierGroup.fromJson(
              jsonDecode(row.payloadJson) as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      branches: branchRows
          .map(
            (row) => MenuBranch.fromJson(
              jsonDecode(row.payloadJson) as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> write({
    required MenuCacheQuery scope,
    required MenuDataBundle bundle,
  }) async {
    await _db.transaction(() async {
      await _db
          .into(_db.menuCacheScopes)
          .insertOnConflictUpdate(
            MenuCacheScopesCompanion.insert(
              tenantId: scope.tenantId,
              scopeKey: scope.scopeKey,
              cachedAt: DateTime.now(),
            ),
          );

      await (_db.delete(_db.menuItemCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      for (var index = 0; index < bundle.items.length; index++) {
        await _db
            .into(_db.menuItemCacheEntries)
            .insert(
              MenuItemCacheEntriesCompanion.insert(
                tenantId: scope.tenantId,
                scopeKey: scope.scopeKey,
                itemId: bundle.items[index].id,
                sortOrder: index,
                payloadJson: jsonEncode(bundle.items[index].toJson()),
              ),
            );
      }

      await (_db.delete(_db.menuCategoryCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      for (var index = 0; index < bundle.categories.length; index++) {
        await _db
            .into(_db.menuCategoryCacheEntries)
            .insert(
              MenuCategoryCacheEntriesCompanion.insert(
                tenantId: scope.tenantId,
                scopeKey: scope.scopeKey,
                categoryId: bundle.categories[index].id,
                sortOrder: index,
                payloadJson: jsonEncode(bundle.categories[index].toJson()),
              ),
            );
      }

      await (_db.delete(_db.menuModifierGroupCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      for (var index = 0; index < bundle.modifierGroups.length; index++) {
        await _db
            .into(_db.menuModifierGroupCacheEntries)
            .insert(
              MenuModifierGroupCacheEntriesCompanion.insert(
                tenantId: scope.tenantId,
                scopeKey: scope.scopeKey,
                groupId: bundle.modifierGroups[index].id,
                sortOrder: index,
                payloadJson: jsonEncode(bundle.modifierGroups[index].toJson()),
              ),
            );
      }

      await (_db.delete(_db.menuBranchCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      for (var index = 0; index < bundle.branches.length; index++) {
        await _db
            .into(_db.menuBranchCacheEntries)
            .insert(
              MenuBranchCacheEntriesCompanion.insert(
                tenantId: scope.tenantId,
                scopeKey: scope.scopeKey,
                branchId: bundle.branches[index].id,
                sortOrder: index,
                payloadJson: jsonEncode(bundle.branches[index].toJson()),
              ),
            );
      }
    });
  }

  @override
  Future<void> clear(MenuCacheQuery scope) async {
    await _db.transaction(() async {
      await (_db.delete(_db.menuCacheScopes)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      await (_db.delete(_db.menuItemCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      await (_db.delete(_db.menuCategoryCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      await (_db.delete(_db.menuModifierGroupCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
      await (_db.delete(_db.menuBranchCacheEntries)
            ..where((tbl) => tbl.tenantId.equals(scope.tenantId))
            ..where((tbl) => tbl.scopeKey.equals(scope.scopeKey)))
          .go();
    });
  }
}

final menuCacheStoreProvider = Provider<MenuCacheStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftMenuCacheStore(db);
});
