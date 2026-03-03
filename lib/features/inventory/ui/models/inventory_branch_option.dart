import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class InventoryBranchOption {
  const InventoryBranchOption({required this.id, required this.name});

  final String id;
  final String name;
}

List<InventoryBranchOption> buildInventoryBranchOptions({
  required List<StockItem> items,
  required List<UserBranch> userBranches,
}) {
  final map = <String, String>{};
  if (userBranches.isNotEmpty) {
    for (final branch in userBranches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      map[id] = branch.name;
    }
  } else {
    for (final item in items) {
      map[item.branchId] = item.branchName;
    }
  }

  final entries =
      map.entries
          .map(
            (entry) => InventoryBranchOption(id: entry.key, name: entry.value),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  if (entries.every((entry) => entry.id != 'all')) {
    entries.insert(
      0,
      const InventoryBranchOption(id: 'all', name: 'All Branches'),
    );
  }
  return entries;
}
