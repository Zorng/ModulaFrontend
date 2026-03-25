import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class MenuModifierOptionEffect {
  const MenuModifierOptionEffect({
    required this.modifierOptionId,
    required this.components,
  });

  final String modifierOptionId;
  final List<ModifierDelta> components;

  factory MenuModifierOptionEffect.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        json['components'] as List<dynamic>? ?? const <dynamic>[];
    return MenuModifierOptionEffect(
      modifierOptionId: json['modifierOptionId']?.toString() ?? '',
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
      'components': components
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}
