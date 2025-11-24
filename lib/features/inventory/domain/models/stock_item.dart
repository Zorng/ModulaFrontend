import 'package:equatable/equatable.dart';

class StockItem extends Equatable {
  const StockItem({
    required this.id,
    required this.name,
    required this.category,
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
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      baseUnit: json['baseUnit'] as String? ?? 'pcs',
      pieceSize: json['pieceSize'] as int? ?? 1,
      branchId: json['branchId'] as String? ?? 'main',
      branchName: json['branchName'] as String? ?? 'Main Branch',
      onHand: json['onHand'] as int,
      minThreshold: json['minThreshold'] as int,
      isActive: json['isActive'] as bool? ?? true,
      barcode: json['barcode'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastRestockDate: json['lastRestockDate'] as String? ?? '-',
      expiryDate: json['expiryDate'] as String? ?? '-',
      usageTags: (json['usageTags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
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
