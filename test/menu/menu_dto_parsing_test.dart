import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

void main() {
  group('Menu DTO parsing', () {
    test('MenuItemDto normalizes status and visibleBranchIds', () {
      final dto = MenuItemDto.fromJson({
        'id': 'item-1',
        'tenantId': 'tenant-1',
        'name': 'Iced Latte',
        'categoryId': 'cat-1',
        'basePrice': '2.75',
        'status': 'unknown',
        'isActive': false,
        'imageUrl': ' https://cdn.example.com/menu/item-1.png ',
        'modifierGroupIds': [
          {'id': 'group-1'},
          'group-2',
        ],
        'visibleBranchIds': ['branch-1', ' branch-2 ', ''],
      });

      expect(dto.basePrice, 2.75);
      expect(dto.priceUsd, 2.75);
      expect(dto.status, 'ARCHIVED');
      expect(dto.isActive, isFalse);
      expect(dto.imageUrl, 'https://cdn.example.com/menu/item-1.png');
      expect(dto.modifierGroupIds, ['group-1', 'group-2']);
      expect(dto.visibleBranchIds, ['branch-1', 'branch-2']);
      expect(dto.branchIds, ['branch-1', 'branch-2']);
    });

    test('MenuCategoryDto normalizes status fallback from isActive', () {
      final dto = MenuCategoryDto.fromJson({
        'id': 'cat-1',
        'tenantId': 'tenant-1',
        'name': 'Coffee',
        'status': '',
        'isActive': 0,
        'displayOrder': '2',
      });

      expect(dto.status, 'ARCHIVED');
      expect(dto.isActive, isFalse);
      expect(dto.displayOrder, 2);
    });

    test('ModifierGroupDto normalizes selection mode and nested options', () {
      final dto = ModifierGroupDto.fromJson({
        'id': 'group-1',
        'tenantId': 'tenant-1',
        'name': 'Milk',
        'selectionMode': 'multiple',
        'isRequired': true,
        'status': 'active',
        'options': [
          {
            'id': 'opt-1',
            'groupId': 'group-1',
            'label': 'Oat Milk',
            'priceDelta': '0.50',
            'status': 'active',
            'componentDeltas': [
              {
                'stockItemId': 'stock-1',
                'quantityDeltaInBaseUnit': '1.25',
                'trackingMode': 'DEDUCT',
              },
            ],
          },
          {
            'id': 'opt-2',
            'groupId': 'group-1',
            'label': 'Soy Milk',
            'priceDelta': 0,
            'status': 'unknown',
            'isActive': false,
          },
        ],
      });

      expect(dto.selectionMode, 'MULTI');
      expect(dto.minSelections, 0);
      expect(dto.maxSelections, 99);
      expect(dto.status, 'ACTIVE');
      expect(dto.options.length, 2);
      expect(dto.options.first.priceDelta, 0.5);
      expect(dto.options.first.componentDeltas.length, 1);
      expect(
        dto.options.first.componentDeltas.first.quantityDeltaInBaseUnit,
        1.25,
      );
      expect(dto.options.last.status, 'ARCHIVED');
      expect(dto.options.last.isActive, isFalse);
    });

    test('MenuCompositionEvaluateDto parses component list', () {
      final dto = MenuCompositionEvaluateDto.fromJson({
        'menuItemId': 'item-1',
        'components': [
          {
            'stockItemId': 'stock-1',
            'quantityInBaseUnit': '2.5',
            'trackingMode': 'DEDUCT',
          },
        ],
      });

      expect(dto.menuItemId, 'item-1');
      expect(dto.components.length, 1);
      expect(dto.components.first.stockItemId, 'stock-1');
      expect(dto.components.first.quantityInBaseUnit, 2.5);
      expect(dto.components.first.trackingMode, 'DEDUCT');
    });
  });
}
