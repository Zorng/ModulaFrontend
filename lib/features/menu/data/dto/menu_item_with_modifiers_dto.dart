import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

class MenuItemWithModifiersDto {
  const MenuItemWithModifiersDto({
    required this.item,
    required this.modifierGroups,
  });

  final MenuItemDto item;
  final List<ModifierGroupDto> modifierGroups;

  factory MenuItemWithModifiersDto.fromJson(Map<String, dynamic> raw) {
    final data = raw['data'];
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(raw);

    final item = MenuItemDto.fromJson(payload);

    final rawModifiers = payload['modifiers'] as List<dynamic>? ?? const [];
    final groups = <ModifierGroupDto>[];

    for (final entry in rawModifiers) {
      if (entry is! Map) continue;
      final entryMap = Map<String, dynamic>.from(entry);
      final groupJson = entryMap['group'];
      if (groupJson is! Map) continue;
      final groupMap = Map<String, dynamic>.from(groupJson);

      final optionsRaw = entryMap['options'] as List<dynamic>? ?? const [];
      final options = optionsRaw
          .whereType<Map>()
          .map((opt) => ModifierOptionDto.fromJson(
                Map<String, dynamic>.from(opt),
              ))
          .where((o) => o.id.isNotEmpty)
          .toList(growable: false);

      final group = ModifierGroupDto.fromJson({
        ...groupMap,
        'options': options.map((o) {
          return {
            'id': o.id,
            'label': o.label,
            'priceAdjustmentUsd': o.priceAdjustmentUsd,
            'isDefault': o.isDefault,
            'isActive': o.isActive,
          };
        }).toList(growable: false),
        'pricingBehavior': groupMap['pricingBehavior'] ?? 'addon',
        'isRequired': entryMap['isRequired'],
      });

      if (group.id.isNotEmpty) {
        groups.add(group);
      }
    }

    return MenuItemWithModifiersDto(
      item: item,
      modifierGroups: groups,
    );
  }
}

