import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MenuModifierOptionEffect {
  const MenuModifierOptionEffect({
    required this.modifierOptionId,
    required this.priceDelta,
    required this.components,
  });

  final String modifierOptionId;
  final double priceDelta;
  final List<ModifierDelta> components;

  factory MenuModifierOptionEffect.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        json['components'] as List<dynamic>? ?? const <dynamic>[];
    return MenuModifierOptionEffect(
      modifierOptionId: json['modifierOptionId']?.toString() ?? '',
      priceDelta: _asDouble(json['priceDelta']),
      components: rawComponents
          .whereType<Map>()
          .map(
            (entry) => ModifierDelta.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'modifierOptionId': modifierOptionId,
      'priceDelta': priceDelta,
      'components': components
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}
