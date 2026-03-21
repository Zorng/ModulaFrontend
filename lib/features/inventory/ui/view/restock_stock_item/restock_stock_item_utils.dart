import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

List<MapEntry<String, String>> buildBranchEntries(
  List<StockItem> items, {
  List<BranchListItem> tenantBranches = const <BranchListItem>[],
  List<UserBranch> fallbackBranches = const <UserBranch>[],
}) {
  final map = <String, String>{};
  if (tenantBranches.isNotEmpty) {
    for (final branch in tenantBranches) {
      final id = branch.branchId.trim();
      if (id.isEmpty) continue;
      final name = branch.branchName.trim().isNotEmpty
          ? branch.branchName.trim()
          : id;
      map[id] = name;
    }
  } else if (fallbackBranches.isNotEmpty) {
    for (final branch in fallbackBranches) {
      final id = (branch.branchId.isNotEmpty ? branch.branchId : branch.id)
          .trim();
      if (id.isEmpty) continue;
      final name = branch.name.trim().isNotEmpty ? branch.name.trim() : id;
      map[id] = name;
    }
  } else {
    for (final item in items) {
      final id = item.branchId.trim();
      if (id.isEmpty) continue;
      final name = item.branchName.trim().isNotEmpty
          ? item.branchName.trim()
          : id;
      map[id] = name;
    }
  }
  final entries = map.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return entries;
}

DateTime? parseYyyyMmDd(String value) {
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String formatYyyyMmDd(DateTime date) => date.toIso8601String().split('T').first;
