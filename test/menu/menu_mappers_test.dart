import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
import 'package:modular_pos/features/menu/data/menu_mappers.dart';

void main() {
  group('MenuMappers', () {
    test('toItem maps normalized status and visible branches', () {
      final dto = MenuItemDto.fromJson({
        'id': 'item-1',
        'tenantId': 'tenant-1',
        'name': 'Americano',
        'categoryId': 'cat-1',
        'basePrice': 2,
        'status': 'unknown',
        'isActive': false,
        'visibleBranchIds': ['branch-1'],
      });

      final item = MenuMappers.toItem(dto);

      expect(item.id, 'item-1');
      expect(item.basePrice, 2);
      expect(item.price, 2);
      expect(item.status, 'ARCHIVED');
      expect(item.isActive, isFalse);
      expect(item.visibleBranchIds, ['branch-1']);
      expect(item.branchIds, ['branch-1']);
    });

    test('toGroup filters archived options and normalizes selection mode', () {
      final dto = ModifierGroupDto.fromJson({
        'id': 'group-1',
        'tenantId': 'tenant-1',
        'name': 'Toppings',
        'selectionMode': 'multiple',
        'status': 'active',
        'options': [
          {
            'id': 'opt-1',
            'groupId': 'group-1',
            'label': 'Whipped Cream',
            'priceDelta': 0.5,
            'status': 'active',
          },
          {
            'id': 'opt-2',
            'groupId': 'group-1',
            'label': 'No Foam',
            'priceDelta': 0,
            'status': 'archived',
          },
        ],
      });

      final group = MenuMappers.toGroup(dto);

      expect(group.selectionMode, 'MULTI');
      expect(group.selectionType, 'multiple');
      expect(group.status, 'ACTIVE');
      expect(group.options.map((o) => o.id).toList(), ['opt-1']);
    });

    test('normalizeStatus uses fallback deterministically', () {
      expect(
        MenuMappers.normalizeStatus('  ', fallbackIsActive: true),
        'ACTIVE',
      );
      expect(
        MenuMappers.normalizeStatus('invalid', fallbackIsActive: false),
        'ARCHIVED',
      );
    });
  });
}
