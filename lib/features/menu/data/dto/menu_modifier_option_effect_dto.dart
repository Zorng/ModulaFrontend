import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

class MenuModifierOptionEffectDto {
  const MenuModifierOptionEffectDto({
    required this.modifierOptionId,
    required this.priceDelta,
    required this.components,
  });

  final String modifierOptionId;
  final double priceDelta;
  final List<ModifierDeltaDto> components;

  factory MenuModifierOptionEffectDto.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        json['componentDeltas'] as List<dynamic>? ??
        json['components'] as List<dynamic>? ??
        const <dynamic>[];
    return MenuModifierOptionEffectDto(
      modifierOptionId: json['modifierOptionId']?.toString() ?? '',
      priceDelta: _asDouble(json['priceDelta']),
      components: rawComponents
          .whereType<Map>()
          .map(
            (entry) =>
                ModifierDeltaDto.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'modifierOptionId': modifierOptionId,
      'priceDelta': priceDelta,
      'componentDeltas': components
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}

class MenuModifierOptionEffectsUpsertRequestDto {
  const MenuModifierOptionEffectsUpsertRequestDto({required this.effects});

  final List<MenuModifierOptionEffectDto> effects;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'effects': effects.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
