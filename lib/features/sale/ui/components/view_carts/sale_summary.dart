class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.state,
    required this.createdAt,
    required this.lines,
  });

  final String id;
  final String state;
  final DateTime createdAt;
  final List<SaleLine> lines;

  factory SaleSummary.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now();
    final lines = <SaleLine>[];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is! Map<String, dynamic>) continue;
        final mods = <String>[];
        if (item['modifiers'] is List) {
          for (final m in item['modifiers'] as List) {
            if (m is! Map<String, dynamic>) continue;
            final options = m['options'];
            if (options is List) {
              for (final o in options) {
                if (o is Map<String, dynamic>) {
                  final label = o['label']?.toString() ?? o['name']?.toString();
                  if (label != null && label.isNotEmpty) mods.add(label);
                }
              }
            }
          }
        }
        lines.add(
          SaleLine(
            name: item['menuItemName']?.toString() ?? 'Item',
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            modifiers: mods,
          ),
        );
      }
    }
    return SaleSummary(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      createdAt: created,
      lines: lines,
    );
  }
}

class SaleLine {
  const SaleLine({
    required this.name,
    required this.quantity,
    required this.modifiers,
  });

  final String name;
  final int quantity;
  final List<String> modifiers;
}

