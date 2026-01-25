import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

List<MapEntry<String, String>> buildBranchEntries(
  List<StockItem> items,
  List<UserBranch> userBranches,
) {
  final map = <String, String>{};
  if (userBranches.isNotEmpty) {
    for (final b in userBranches) {
      final id = b.branchId.isNotEmpty ? b.branchId : b.id;
      map[id] = b.name;
    }
  } else {
    for (final item in items) {
      map[item.branchId] = item.branchName;
    }
  }
  final entries = map.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  return entries;
}

List<StockItem> itemsForBranch(List<StockItem> items, String branchId) {
  final sorted = [...items]..sort((a, b) => a.name.compareTo(b.name));
  return sorted.where((item) => item.branchId == branchId).toList();
}

DateTime? parseYyyyMmDd(String value) {
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String formatYyyyMmDd(DateTime date) => date.toIso8601String().split('T').first;

