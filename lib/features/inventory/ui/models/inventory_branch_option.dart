import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class InventoryBranchOption {
  const InventoryBranchOption({required this.id, required this.name});

  final String id;
  final String name;
}

List<InventoryBranchOption> buildInventoryBranchOptions({
  required List<StockItem> items,
  List<BranchListItem> tenantBranches = const <BranchListItem>[],
  List<UserBranch> userBranches = const <UserBranch>[],
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
  } else if (userBranches.isNotEmpty) {
    for (final branch in userBranches) {
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
