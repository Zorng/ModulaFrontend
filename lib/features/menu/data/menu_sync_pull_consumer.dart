import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/features/menu/data/menu_cache_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

final menuSyncPullConsumerProvider = Provider<SyncPullConsumer>((ref) {
  final cacheStore = ref.watch(menuCacheStoreProvider);
  return MenuSyncPullConsumer(cacheStore);
});

class MenuSyncPullConsumer implements SyncPullConsumer {
  MenuSyncPullConsumer(this._cacheStore);

  final MenuCacheStore _cacheStore;

  static const _bundleKeys = <String>['menu', 'catalog', 'snapshot', 'data'];
  static const _itemKeys = <String>['items', 'menuItems'];
  static const _categoryKeys = <String>['categories', 'menuCategories'];
  static const _groupKeys = <String>['modifierGroups', 'groups', 'modifiers'];
  static const _branchKeys = <String>['branches', 'visibleBranches'];

  @override
  SyncModuleScope get scope => SyncModuleScope.menu;

  @override
  Future<void> apply({
    required SyncPullContext context,
    required dynamic payload,
    required String? cursor,
    required DateTime pulledAt,
  }) async {
    final branchId = context.branchId.trim();
    if (branchId.isEmpty) {
      throw StateError('Menu sync pull requires an active branch context.');
    }

    final bundle = _extractBundle(payload);
    if (!_looksLikeBundle(bundle)) return;

    final scope = MenuCacheQuery(
      tenantId: context.tenantId.trim(),
      scopeKey: buildMenuCacheScopeKey(
        readLane: MenuReadLane.branchContext,
        status: 'active',
        branchIdFilter: branchId,
      ),
      readLane: MenuReadLane.branchContext,
      status: 'active',
      branchIdFilter: branchId,
    );

    final existing = await _cacheStore.read(scope);

    final hasItems = _containsList(bundle, _itemKeys);
    final hasCategories = _containsList(bundle, _categoryKeys);
    final hasGroups = _containsList(bundle, _groupKeys);
    final hasBranches = _containsList(bundle, _branchKeys);

    final items = hasItems
        ? _extractList(bundle, _itemKeys)
              .map((entry) => ApiContract.asJsonMap(entry))
              .where((entry) => entry.isNotEmpty)
              .map(MenuItem.fromJson)
              .toList(growable: false)
        : (existing?.items ?? const <MenuItem>[]);

    final categories = hasCategories
        ? _extractList(bundle, _categoryKeys)
              .map((entry) => ApiContract.asJsonMap(entry))
              .where((entry) => entry.isNotEmpty)
              .map(MenuCategory.fromJson)
              .toList(growable: false)
        : (existing?.categories ?? const <MenuCategory>[]);

    final modifierGroups = hasGroups
        ? _extractList(bundle, _groupKeys)
              .map((entry) => ApiContract.asJsonMap(entry))
              .where((entry) => entry.isNotEmpty)
              .map(ModifierGroup.fromJson)
              .toList(growable: false)
        : (existing?.modifierGroups ?? const <ModifierGroup>[]);

    final branches = hasBranches
        ? _extractList(bundle, _branchKeys)
              .map((entry) => ApiContract.asJsonMap(entry))
              .where((entry) => entry.isNotEmpty)
              .map(MenuBranch.fromJson)
              .toList(growable: false)
        : (existing?.branches ?? const <MenuBranch>[]);

    await _cacheStore.write(
      scope: scope,
      bundle: MenuDataBundle(
        items: items,
        categories: categories,
        modifierGroups: modifierGroups,
        branches: branches,
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
    return _itemKeys.any(value.containsKey) ||
        _categoryKeys.any(value.containsKey) ||
        _groupKeys.any(value.containsKey) ||
        _branchKeys.any(value.containsKey);
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
