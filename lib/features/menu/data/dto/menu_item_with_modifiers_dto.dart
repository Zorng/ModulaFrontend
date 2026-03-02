import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

class MenuItemWithModifiersDto {
  const MenuItemWithModifiersDto({
    required this.item,
    required this.modifierGroups,
    required this.categoryName,
  });

  final MenuItemDto item;
  final List<ModifierGroupDto> modifierGroups;
  final String? categoryName;

  factory MenuItemWithModifiersDto.fromJson(Map<String, dynamic> raw) {
    final data = raw['data'];
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(raw);

    final item = MenuItemDto.fromJson(payload);
    final groups = _parseModifierGroups(payload);

    return MenuItemWithModifiersDto(
      item: item,
      modifierGroups: groups,
      categoryName: payload['categoryName']?.toString(),
    );
  }
}

List<ModifierGroupDto> _parseModifierGroups(Map<String, dynamic> payload) {
  final directGroupsRaw =
      payload['modifierGroups'] as List<dynamic>? ?? const <dynamic>[];
  if (directGroupsRaw.isNotEmpty) {
    return directGroupsRaw
        .whereType<Map>()
        .map(
          (entry) =>
              ModifierGroupDto.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((group) => group.id.isNotEmpty)
        .toList(growable: false);
  }

  // Legacy fallback shape (`modifiers: [{ group, options }]`) kept until
  // MENU-REF cutover is completed.
  final rawModifiers =
      payload['modifiers'] as List<dynamic>? ?? const <dynamic>[];
  final groups = <ModifierGroupDto>[];

  for (final entry in rawModifiers) {
    if (entry is! Map) continue;
    final entryMap = Map<String, dynamic>.from(entry);
    final groupJson = entryMap['group'];
    if (groupJson is! Map) continue;
    final groupMap = Map<String, dynamic>.from(groupJson);

    final optionsRaw =
        entryMap['options'] as List<dynamic>? ?? const <dynamic>[];
    final options = optionsRaw
        .whereType<Map>()
        .map(
          (opt) => ModifierOptionDto.fromJson(Map<String, dynamic>.from(opt)),
        )
        .where((option) => option.id.isNotEmpty)
        .toList(growable: false);

    final group = ModifierGroupDto.fromJson({
      ...groupMap,
      'options': options
          .map((option) => option.toJson())
          .toList(growable: false),
      'isRequired': entryMap['isRequired'],
    });

    if (group.id.isNotEmpty) {
      groups.add(group);
    }
  }

  return groups;
}
