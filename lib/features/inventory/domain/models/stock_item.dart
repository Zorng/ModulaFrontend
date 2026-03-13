import 'package:equatable/equatable.dart';

const Object _stockItemUnset = Object();

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
    Object? categoryId = _stockItemUnset,
    String? baseUnit,
    int? pieceSize,
    String? branchId,
    String? branchName,
    int? onHand,
    int? minThreshold,
    bool? isActive,
    Object? imageUrl = _stockItemUnset,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: identical(categoryId, _stockItemUnset)
          ? this.categoryId
          : categoryId as String?,
      baseUnit: baseUnit ?? this.baseUnit,
      pieceSize: pieceSize ?? this.pieceSize,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      onHand: onHand ?? this.onHand,
      minThreshold: minThreshold ?? this.minThreshold,
      isActive: isActive ?? this.isActive,
      imageUrl: identical(imageUrl, _stockItemUnset)
          ? this.imageUrl
          : imageUrl as String?,
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
