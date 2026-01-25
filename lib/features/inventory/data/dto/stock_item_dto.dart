class StockItemDto {
  const StockItemDto({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unitText,
    required this.pieceSize,
    required this.barcode,
    required this.imageUrl,
    required this.isActive,
    required this.usageTags,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String unitText;
  final int pieceSize;
  final String? barcode;
  final String? imageUrl;
  final bool isActive;
  final List<String> usageTags;

  factory StockItemDto.fromJson(Map<String, dynamic> json) {
    final id = (json['stockItemId'] ??
            json['stock_item_id'] ??
            json['id'] ??
            '')
        .toString();
    final imageUrl = (() {
      final raw = json['imageUrl'] ??
          json['image_url'] ??
          json['image'] ??
          (json['image'] is Map ? (json['image'] as Map)['url'] : null);
      final trimmed = raw?.toString().trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    })();
    final categoryId = json['categoryId']?.toString() ?? json['category_id']?.toString();
    final tags = (json['usageTags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return StockItemDto(
      id: id,
      name: json['name']?.toString() ?? 'Item',
      categoryId: (categoryId != null && categoryId.isNotEmpty) ? categoryId : null,
      unitText:
          json['unitText']?.toString() ?? json['baseUnit']?.toString() ?? 'pcs',
      pieceSize: _asInt(json['pieceSize']) ?? 1,
      barcode: json['barcode']?.toString(),
      imageUrl: imageUrl,
      isActive: _asBool(json['isActive'], fallback: true),
      usageTags: tags,
    );
  }
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

