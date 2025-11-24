import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the raw API client for the menu feature.
final menuApiProvider = Provider<MenuApi>((ref) {
  // In a real app, you would pass a Dio client here:
  // final dio = ref.watch(dioProvider);
  // return MenuApi(dio);
  return MenuApi();
});

/// Handles the raw network requests for menu data.
class MenuApi {
  // final Dio _dio;
  // MenuApi(this._dio);

  /// Fetches a list of menu items from the backend.
  ///
  /// In a real implementation, this would make a GET request using Dio.
  /// Here, it returns a mock list of raw JSON objects.
  Future<List<Map<String, dynamic>>> fetchMenuItems() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate latency
    return List.generate(20, (index) {
      final category = ['Coffee', 'Tea', 'Pastries'][index % 3];
      return {
        'id': 'item-$index',
        'name': '$category Item ${index + 1}',
        'category': category,
        'price': 3.50 + (index * 0.25),
        'imagePath': 'assets/images/latte.jpg',
      };
    });
  }
}