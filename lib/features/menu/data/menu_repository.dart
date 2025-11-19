import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';

/// Provider for the menu repository.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final menuApi = ref.watch(menuApiProvider);
  return MenuRepository(menuApi);
});

/// Repository for the menu feature.
///
/// It uses the [MenuApi] to fetch raw data and parses it into domain models.
class MenuRepository {
  const MenuRepository(this._api);
  final MenuApi _api;

  /// Fetches menu items and returns them as a list of [MenuItem] models.
  Future<List<MenuItem>> getMenuItems() async {
    final rawItems = await _api.fetchMenuItems();
    return rawItems.map((json) => MenuItem.fromJson(json)).toList();
  }
}