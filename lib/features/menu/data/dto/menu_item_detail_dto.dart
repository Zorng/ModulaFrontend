import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_modifier_option_effect_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

class MenuItemDetailDto {
  const MenuItemDetailDto({
    required this.item,
    required this.modifierGroups,
    required this.baseComponents,
    required this.modifierOptionEffects,
    this.categoryName,
  });

  final MenuItemDto item;
  final List<ModifierGroupDto> modifierGroups;
  final List<MenuComponentDto> baseComponents;
  final List<MenuModifierOptionEffectDto> modifierOptionEffects;
  final String? categoryName;

  factory MenuItemDetailDto.fromJson(Map<String, dynamic> raw) {
    final data = raw['data'];
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : Map<String, dynamic>.from(raw);

    final item = MenuItemDto.fromJson(payload);
    final modifierGroups = _parseModifierGroups(payload);
    final baseComponents = _parseBaseComponents(payload);
    final modifierOptionEffects = _parseModifierOptionEffects(payload);

    return MenuItemDetailDto(
      item: item,
      modifierGroups: modifierGroups,
      baseComponents: baseComponents,
      modifierOptionEffects: modifierOptionEffects,
      categoryName: payload['categoryName']?.toString(),
    );
  }
}

List<MenuComponentDto> _parseBaseComponents(Map<String, dynamic> payload) {
  final rawComponents =
      payload['baseComponents'] as List<dynamic>? ?? const <dynamic>[];
  return rawComponents
      .whereType<Map>()
      .map(
        (entry) => MenuComponentDto.fromJson(Map<String, dynamic>.from(entry)),
      )
      .where((entry) => entry.stockItemId.isNotEmpty)
      .toList(growable: false);
}

List<MenuModifierOptionEffectDto> _parseModifierOptionEffects(
  Map<String, dynamic> payload,
) {
  final rawEffects =
      payload['modifierOptionEffects'] as List<dynamic>? ?? const <dynamic>[];
  return rawEffects
      .whereType<Map>()
      .map(
        (entry) => MenuModifierOptionEffectDto.fromJson(
          Map<String, dynamic>.from(entry),
        ),
      )
      .where((entry) => entry.modifierOptionId.isNotEmpty)
      .toList(growable: false);
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
