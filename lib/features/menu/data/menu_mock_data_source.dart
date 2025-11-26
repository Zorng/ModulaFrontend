import 'dart:math';

class MenuMockDataSource {
  MenuMockDataSource({int branchCount = 1}) {
    _branches = _generateBranches(branchCount);
    _seedSampleData();
  }

  late final List<Map<String, dynamic>> _branches;
  late List<Map<String, dynamic>> _categories;
  late List<Map<String, dynamic>> _modifierGroups;
  late List<Map<String, dynamic>> _menuItems;

  final _rand = Random();
  final Map<String, int> _idCounters = {};

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    return List<Map<String, dynamic>>.from(_branches);
  }

  Future<List<Map<String, dynamic>>> fetchCategories({bool? isActive}) async {
    if (isActive == null) {
      return List<Map<String, dynamic>>.from(_categories);
    }
    return _categories
        .where((category) => category['isActive'] == isActive)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchModifierGroups() async {
    return List<Map<String, dynamic>>.from(_modifierGroups);
  }

  Future<List<Map<String, dynamic>>> fetchModifierOptions(String groupId) async {
    final group =
        _modifierGroups.firstWhere((g) => g['id'] == groupId, orElse: () => {});
    final options = group['options'] as List<dynamic>? ?? const [];
    return options.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchMenuItems() async {
    return List<Map<String, dynamic>>.from(_menuItems);
  }

  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> payload) async {
    final category = {
      ...payload,
      'id': _resolveId(payload['id'], 'cat'),
    };
    _categories.add(category);
    return category;
  }

  Future<Map<String, dynamic>> updateCategory(
      Map<String, dynamic> payload) async {
    final index = _categories.indexWhere((c) => c['id'] == payload['id']);
    if (index == -1) {
      throw StateError('Category ${payload['id']} not found');
    }
    _categories[index] = {..._categories[index], ...payload};
    return _categories[index];
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c['id'] == categoryId);
  }

  Future<Map<String, dynamic>> createModifierGroup(
      Map<String, dynamic> payload) async {
    final group = {
      ...payload,
      'id': _resolveId(payload['id'], 'mod'),
      'options': payload['options'] ?? const [],
    };
    _modifierGroups.add(group);
    return group;
  }

  Future<Map<String, dynamic>> updateModifierGroup(
      Map<String, dynamic> payload) async {
    final index = _modifierGroups.indexWhere((c) => c['id'] == payload['id']);
    if (index == -1) {
      throw StateError('Modifier group ${payload['id']} not found');
    }
    _modifierGroups[index] = {..._modifierGroups[index], ...payload};
    return _modifierGroups[index];
  }

  Future<Map<String, dynamic>> addModifierOption(
      Map<String, dynamic> payload) async {
    final groupId = payload['modifierGroupId'];
    final index =
        _modifierGroups.indexWhere((group) => group['id'] == groupId);
    if (index == -1) {
      throw StateError('Modifier group not found');
    }
    final option = {
      'id': _generateId('opt'),
      'label': payload['label'],
      'priceAdjustmentUsd': payload['priceAdjustmentUsd'],
      'isDefault': payload['isDefault'],
    };
    final options =
        List<Map<String, dynamic>>.from(_modifierGroups[index]['options'] as List? ?? []);
    options.add(option);
    _modifierGroups[index] = {
      ..._modifierGroups[index],
      'options': options,
      if (payload['isDefault'] == true) 'defaultOptionId': option['id'],
    };
    return option;
  }

  Future<void> attachModifierToItem(
    String menuItemId,
    Map<String, dynamic> payload,
  ) async {
    final menuIndex = _menuItems.indexWhere((item) => item['id'] == menuItemId);
    if (menuIndex == -1) return;
    final existing =
        List<String>.from(_menuItems[menuIndex]['modifierGroupIds'] as List? ?? []);
    final modifierGroupId = payload['modifierGroupId']?.toString();
    if (modifierGroupId != null && !existing.contains(modifierGroupId)) {
      existing.add(modifierGroupId);
      _menuItems[menuIndex] = {
        ..._menuItems[menuIndex],
        'modifierGroupIds': existing,
      };
    }
  }

  Future<Map<String, dynamic>> createMenuItem(
      Map<String, dynamic> payload) async {
    final branchIds = (payload['branchIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (payload['branchId'] != null
            ? [payload['branchId'].toString()]
            : _branches.map((b) => b['id'] as String).toList());
    final item = {
      ...payload,
      'id': _resolveId(payload['id'], 'item'),
      'branchIds': branchIds,
    };
    _menuItems.insert(0, item);
    return item;
  }

  Future<Map<String, dynamic>> updateMenuItem(
      Map<String, dynamic> payload) async {
    final index = _menuItems.indexWhere((c) => c['id'] == payload['id']);
    if (index == -1) {
      throw StateError('Menu item ${payload['id']} not found');
    }
    final branchIds = (payload['branchIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (payload['branchId'] != null
            ? [payload['branchId'].toString()]
            : (_menuItems[index]['branchIds'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList());
    _menuItems[index] = {
      ..._menuItems[index],
      ...payload,
      'branchIds': branchIds,
    };
    return _menuItems[index];
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    _menuItems.removeWhere((item) => item['id'] == menuItemId);
  }

  Future<void> setBranchAvailability({
    required String menuItemId,
    required String branchId,
    required bool isAvailable,
  }) async {
    final menuIndex = _menuItems.indexWhere((item) => item['id'] == menuItemId);
    if (menuIndex == -1) return;
    final availability = Map<String, bool>.from(
      _menuItems[menuIndex]['availability'] as Map? ?? {},
    );
    availability[branchId] = isAvailable;
    _menuItems[menuIndex] = {
      ..._menuItems[menuIndex],
      'availability': availability,
    };
  }

  Future<void> setPriceOverride({
    required String menuItemId,
    required String branchId,
    required double priceUsd,
  }) async {
    final menuIndex = _menuItems.indexWhere((item) => item['id'] == menuItemId);
    if (menuIndex == -1) return;
    final overrides = Map<String, double>.from(
      _menuItems[menuIndex]['priceOverrides'] as Map? ?? {},
    );
    overrides[branchId] = priceUsd;
    _menuItems[menuIndex] = {
      ..._menuItems[menuIndex],
      'priceOverrides': overrides,
    };
  }

  List<Map<String, dynamic>> _generateBranches(int branchCount) {
    final normalized = max(1, branchCount);
    return List.generate(normalized, (index) {
      final name = normalized == 1 ? 'Main Branch' : 'Branch ${index + 1}';
      return {
        'id': _generateId('branch'),
        'name': name,
      };
    });
  }

  void _seedSampleData() {
    final categoryCount = 3 + _rand.nextInt(4); // 3-6 categories
    _categories = List.generate(categoryCount, (index) {
      return {
        'id': _generateId('cat'),
        'name': 'Category ${index + 1}',
        'description': 'Auto generated category ${index + 1}',
        'displayOrder': index,
        'isActive': true,
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
          'label': 'Option ${optIndex + 1}',
          'priceAdjustmentUsd': price,
          'isDefault': optIndex == 0 && selectionType == 'single',
        };
      });
      final group = {
        'id': _generateId('mod'),
        'name': 'Modifier Group ${index + 1}',
        'selectionType': selectionType,
        'pricingBehavior': pricingBehavior,
        'defaultOptionId': selectionType == 'single' ? options.first['id'] as String : null,
        'options': options,
      };
      group.removeWhere((key, value) => value == null);
      return group;
    });

    final itemCount = max(5, _categories.length * 2);
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
}
