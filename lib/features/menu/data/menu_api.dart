import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggle whether the mock API should behave like a fresh tenant (no menu data).
/// Flip via `dart define MENU_FRESH_TENANT=false` when launching the app.
const bool _simulateFreshTenantScenario =
    bool.fromEnvironment('MENU_FRESH_TENANT', defaultValue: true);

/// Configure how many branches the mock tenant should have.
/// Default is 1 (single-branch tenant). Override with `--dart-define MENU_BRANCH_COUNT=3`.
const int _mockBranchCount =
    int.fromEnvironment('MENU_BRANCH_COUNT', defaultValue: 1);

/// Provider for the raw API client for the menu feature.
final menuApiProvider = Provider<MenuApi>((ref) {
  return MenuApi(simulateFreshTenant: _simulateFreshTenantScenario);
});

/// Handles the raw network requests for menu data.
///
/// This implementation keeps everything in-memory to simulate a backend.
class MenuApi {
  MenuApi({bool simulateFreshTenant = false}) {
    _branches = _generateBranches();
    if (simulateFreshTenant) {
      _categories = [];
      _modifierGroups = [];
      _menuItems = [];
    } else {
      _seedSampleData();
    }
  }

  late final List<Map<String, dynamic>> _branches;
  late final List<Map<String, dynamic>> _categories;
  late final List<Map<String, dynamic>> _modifierGroups;
  late final List<Map<String, dynamic>> _menuItems;

  final _rand = Random();
  final Map<String, int> _idCounters = {};

  void _seedSampleData() {
    final categoryCount = 3 + _rand.nextInt(4); // 3-6 categories
    _categories = List.generate(categoryCount, (index) {
      return {
        'id': _generateId('cat'),
        'name': 'Category ${index + 1}',
        'description': 'Auto generated category ${index + 1}',
        'isActive': _rand.nextBool(),
      };
    });

    final modifierCount = 1 + _rand.nextInt(3); // 1-3 modifier groups
    _modifierGroups = List.generate(modifierCount, (index) {
      final selectionType = _rand.nextBool() ? 'single' : 'multiple';
      final pricingBehavior = _rand.nextBool() ? 'addon' : 'none';
      final optionCount = 2 + _rand.nextInt(3); // 2-4 options
      final options = List.generate(optionCount, (optIndex) {
        final price = pricingBehavior == 'addon'
            ? double.parse((_rand.nextDouble() * 1.5).toStringAsFixed(2))
            : 0.0;
        return {
          'id': _generateId('opt'),
          'name': 'Option ${optIndex + 1}',
          'price': price,
        };
      });
      final group = {
        'id': _generateId('mod'),
        'name': 'Modifier Group ${index + 1}',
        'selectionType': selectionType,
        'pricingBehavior': pricingBehavior,
        'defaultOptionId':
            selectionType == 'single' ? options.first['id'] as String : null,
        'options': options,
      };
      group.removeWhere((key, value) => value == null);
      return group;
    });

    final itemCount = max(5, categoryCount * 2);
    _menuItems = List.generate(itemCount, (index) {
      final category = _categories[index % _categories.length];
      final branchIds = _randomSubsetFromMaps(_branches);
      final modifiers = _randomSubsetFromMaps(
        _modifierGroups,
        allowEmpty: true,
      );
      final price =
          double.parse((_rand.nextDouble() * 7 + 3).toStringAsFixed(2));
      return {
        'id': _generateId('item'),
        'name': 'Menu Item ${index + 1}',
        'categoryId': category['id'],
        'price': price,
        'imageUrl': null,
        'modifierGroupIds': modifiers,
        'branchIds': branchIds,
        'description': 'Auto generated menu item ${index + 1}',
      };
    });
  }

  List<Map<String, dynamic>> _generateBranches() {
    final branchCount = max(1, _mockBranchCount);
    return List.generate(branchCount, (index) {
      final name = branchCount == 1
          ? 'Main Branch'
          : 'Branch ${index + 1}';
      return {
        'id': _generateId('branch'),
        'name': name,
      };
    });
  }

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<Map<String, dynamic>>.from(_branches);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureIds(_categories, 'cat');
    return List<Map<String, dynamic>>.from(_categories);
  }

  Future<List<Map<String, dynamic>>> fetchModifierGroups() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureIds(_modifierGroups, 'mod');
    return List<Map<String, dynamic>>.from(_modifierGroups);
  }

  Future<List<Map<String, dynamic>>> fetchMenuItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureIds(_menuItems, 'item');
    return List<Map<String, dynamic>>.from(_menuItems);
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> payload) async {
    final category = {
      ...payload,
      'id': _resolveId(payload['id'], 'cat'),
    };
    _categories.add(category);
    return category;
  }

  Future<Map<String, dynamic>> updateCategory(Map<String, dynamic> payload) async {
    final index = _categories.indexWhere((c) => c['id'] == payload['id']);
    if (index == -1) {
      throw StateError('Category ${payload['id']} not found');
    }
    _categories[index] = {..._categories[index], ...payload};
    return _categories[index];
  }

  Future<Map<String, dynamic>> createModifierGroup(Map<String, dynamic> payload) async {
    final group = {
      ...payload,
      'id': _resolveId(payload['id'], 'mod'),
      'options': payload['options'] ?? const [],
    };
    _modifierGroups.add(group);
    return group;
  }

  Future<Map<String, dynamic>> updateModifierGroup(Map<String, dynamic> payload) async {
    final index = _modifierGroups.indexWhere((c) => c['id'] == payload['id']);
    if (index == -1) {
      throw StateError('Modifier group ${payload['id']} not found');
    }
    _modifierGroups[index] = {..._modifierGroups[index], ...payload};
    return _modifierGroups[index];
  }

  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> payload) async {
    final branchIds = (payload['branchIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        _branches.map((b) => b['id'] as String).toList();
    final item = {
      ...payload,
      'id': _resolveId(payload['id'], 'item'),
      'branchIds': branchIds,
    };
    _menuItems.insert(0, item);
    return item;
  }

  Future<Map<String, dynamic>> updateMenuItem(Map<String, dynamic> payload) async {
    final index = _menuItems.indexWhere((c) => c['id'] == payload['id']);
    if (index == -1) {
      throw StateError('Menu item ${payload['id']} not found');
    }
    final branchIds = (payload['branchIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (_menuItems[index]['branchIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
    _menuItems[index] = {
      ..._menuItems[index],
      ...payload,
      'branchIds': branchIds,
    };
    return _menuItems[index];
  }

  List<String> _randomSubsetFromMaps(
    List<Map<String, dynamic>> source, {
    bool allowEmpty = false,
  }) {
    if (source.isEmpty) return [];
    final minCount = allowEmpty ? 0 : 1;
    final maxCount = source.length;
    final effectiveMin = min(minCount, maxCount);
    final pool = List<Map<String, dynamic>>.from(source)..shuffle(_rand);
    final range = maxCount - effectiveMin;
    final count =
        range == 0 ? effectiveMin : effectiveMin + _rand.nextInt(range + 1);
    return pool.take(count).map((e) => e['id'] as String).toList();
  }

  String _generateId(String prefix) {
    final next = (_idCounters[prefix] ?? 0) + 1;
    _idCounters[prefix] = next;
    return '${prefix}_$next';
  }

  String _resolveId(dynamic rawId, String prefix) {
    if (rawId is String && rawId.trim().isNotEmpty) {
      return rawId;
    }
    return _generateId(prefix);
  }

  void _ensureIds(List<Map<String, dynamic>> list, String prefix) {
    for (var i = 0; i < list.length; i++) {
      final id = list[i]['id'];
      if (id is! String || id.trim().isEmpty) {
        list[i] = {...list[i], 'id': _generateId(prefix)};
      }
    }
  }
}
