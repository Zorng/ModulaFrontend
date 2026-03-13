import 'package:equatable/equatable.dart';

class StockItem extends Equatable {
  const StockItem({
    required this.id,
    required this.name,
    this.categoryId,
    required this.baseUnit,
    required this.pieceSize,
    required this.branchId,
    required this.branchName,
    required this.onHand,
    required this.minThreshold,
    required this.isActive,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String baseUnit;
  final int pieceSize;
  final String branchId;
  final String branchName;
  final int onHand;
  final int minThreshold;
  final bool isActive;
  final String? imageUrl;

  bool get isLowStock => onHand < minThreshold;

  StockItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? baseUnit,
    int? pieceSize,
    String? branchId,
    String? branchName,
    int? onHand,
    int? minThreshold,
    bool? isActive,
    String? imageUrl,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      baseUnit: baseUnit ?? this.baseUnit,
      pieceSize: pieceSize ?? this.pieceSize,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      onHand: onHand ?? this.onHand,
      minThreshold: minThreshold ?? this.minThreshold,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    baseUnit,
    pieceSize,
    branchId,
    branchName,
    onHand,
    minThreshold,
    isActive,
    imageUrl,
  ];
}
