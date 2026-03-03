import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_branch_option.dart';

void main() {
  test(
    'buildInventoryBranchOptions uses user-branch context and prepends all',
    () {
      final options = buildInventoryBranchOptions(
        items: const [],
        userBranches: const [
          UserBranch(
            id: 'assignment-1',
            branchId: 'branch-2',
            name: 'North Branch',
            role: 'MANAGER',
            active: true,
          ),
          UserBranch(
            id: 'assignment-2',
            branchId: 'branch-1',
            name: 'Main Branch',
            role: 'MANAGER',
            active: true,
          ),
        ],
      );

      expect(options, hasLength(3));
      expect(options.first.id, 'all');
      expect(options.first.name, 'All Branches');
      expect(options[1].id, 'branch-1');
      expect(options[1].name, 'Main Branch');
      expect(options[2].id, 'branch-2');
      expect(options[2].name, 'North Branch');
    },
  );

  test(
    'buildInventoryBranchOptions falls back to item branches when user branches are absent',
    () {
      final options = buildInventoryBranchOptions(
        items: const [
          StockItem(
            id: 'item-1',
            name: 'Whole Milk',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-2',
            branchName: 'North Branch',
            onHand: 100,
            minThreshold: 20,
            isActive: true,
            imageUrl: null,
          ),
          StockItem(
            id: 'item-2',
            name: 'Raw Sugar',
            categoryId: 'cat-2',
            baseUnit: 'g',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 50,
            minThreshold: 10,
            isActive: true,
            imageUrl: null,
          ),
        ],
        userBranches: const [],
      );

      expect(options, hasLength(3));
      expect(options.first.id, 'all');
      expect(options[1].id, 'branch-1');
      expect(options[2].id, 'branch-2');
    },
  );
}
