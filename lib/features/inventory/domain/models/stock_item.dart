import 'package:equatable/equatable.dart';

class StockItem extends Equatable {
  const StockItem({
    required this.id,
    required this.name,
    required this.category,
    this.categoryId,
    required this.baseUnit,
    required this.pieceSize,
    required this.branchId,
    required this.branchName,
    required this.onHand,
    required this.minThreshold,
    required this.isActive,
    this.barcode,
    this.imageUrl,
    this.lastRestockDate = '-',
    this.expiryDate = '-',
    this.usageTags = const [],
  });

  final String id;
  final String name;
  final String category;
  final String? categoryId;
  final String baseUnit;
  final int pieceSize;
  final String branchId;
  final String branchName;
  final int onHand;
  final int minThreshold;
  final bool isActive;
  final String? barcode;
  final String? imageUrl;
  final String lastRestockDate;
  final String expiryDate;
  final List<String> usageTags;

  bool get isLowStock => onHand < minThreshold;

  StockItem copyWith({
    String? id,
    String? name,
    String? category,
    String? categoryId,
    String? baseUnit,
    int? pieceSize,
    String? branchId,
    String? branchName,
    int? onHand,
    int? minThreshold,
    bool? isActive,
    String? barcode,
    String? imageUrl,
    String? lastRestockDate,
    String? expiryDate,
    List<String>? usageTags,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      baseUnit: baseUnit ?? this.baseUnit,
      pieceSize: pieceSize ?? this.pieceSize,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      onHand: onHand ?? this.onHand,
      minThreshold: minThreshold ?? this.minThreshold,
      isActive: isActive ?? this.isActive,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      expiryDate: expiryDate ?? this.expiryDate,
      usageTags: usageTags ?? this.usageTags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'categoryId': categoryId,
        'baseUnit': baseUnit,
        'pieceSize': pieceSize,
        'branchId': branchId,
        'branchName': branchName,
        'onHand': onHand,
        'minThreshold': minThreshold,
        'isActive': isActive,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'lastRestockDate': lastRestockDate,
        'expiryDate': expiryDate,
        'usageTags': usageTags,
      };

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Item';
    final category = json['category']?.toString() ??
        json['categoryName']?.toString() ??
        'Uncategorized';
    final categoryId = json['categoryId']?.toString();
    final baseUnit = json['baseUnit']?.toString() ??
        json['unitText']?.toString() ??
        'pcs';
    final pieceSize = (json['pieceSize'] as num?)?.toInt() ?? 1;
    final branchId = json['branchId']?.toString() ?? 'main';
    final branchName = json['branchName']?.toString() ?? 'Main Branch';
    final onHand = (json['onHand'] as num?)?.toInt() ?? 0;
    final minThreshold = (json['minThreshold'] as num?)?.toInt() ?? 0;
    final isActive = json['isActive'] as bool? ?? true;
    final barcode = json['barcode']?.toString();
    final imageUrl = json['imageUrl']?.toString();
    final lastRestockDate = json['lastRestockDate']?.toString() ?? '-';
    final expiryDate = json['expiryDate']?.toString() ?? '-';
    final usageTags = (json['usageTags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    return StockItem(
      id: id,
      name: name,
      category: category,
      categoryId: categoryId,
      baseUnit: baseUnit,
      pieceSize: pieceSize,
      branchId: branchId,
      branchName: branchName,
      onHand: onHand,
      minThreshold: minThreshold,
      isActive: isActive,
      barcode: barcode,
      imageUrl: imageUrl,
      lastRestockDate: lastRestockDate,
      expiryDate: expiryDate,
      usageTags: usageTags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        baseUnit,
        pieceSize,
        branchId,
        branchName,
        onHand,
        minThreshold,
        isActive,
        barcode,
        imageUrl,
        lastRestockDate,
        expiryDate,
        usageTags,
      ];
}
