import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';

final discountTenantBranchesProvider = FutureProvider<List<BranchListItem>>((
  ref,
) async {
  final repository = ref.read(branchRepositoryProvider);
  final branches = await repository.loadAccessibleBranches();
  final activeBranches = branches.where((branch) => branch.isActive).toList();
  activeBranches.sort(
    (left, right) =>
        left.branchName.toLowerCase().compareTo(right.branchName.toLowerCase()),
  );
  return activeBranches;
});

final discountBranchMenuItemsProvider =
    FutureProvider.family<List<MenuItem>, String>((ref, branchId) async {
      final normalizedBranchId = branchId.trim();
      if (normalizedBranchId.isEmpty) {
        return const <MenuItem>[];
      }

      final repository = ref.read(menuRepositoryProvider);
      final bundle = await repository.fetchMenuData(
        readLane: MenuReadLane.management,
        status: 'active',
        branchIdFilter: normalizedBranchId,
      );

      final items =
          bundle.items
              .where((item) {
                final visibleBranches = item.visibleBranchIds.isNotEmpty
                    ? item.visibleBranchIds
                    : item.branchIds;
                return visibleBranches.isEmpty ||
                    visibleBranches.contains(normalizedBranchId);
              })
              .toList(growable: false)
            ..sort(
              (left, right) =>
                  left.name.toLowerCase().compareTo(right.name.toLowerCase()),
            );

      return items;
    });
