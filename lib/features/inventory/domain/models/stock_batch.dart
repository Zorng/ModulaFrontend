import 'package:equatable/equatable.dart';

class StockBatch extends Equatable {
  const StockBatch({
    required this.id,
    required this.stockItemId,
    required this.branchId,
    required this.onHand,
    required this.receivedDate,
    this.expiryDate,
  });

  final String id;
  final String stockItemId;
  final String branchId;
  final int onHand;
  final String receivedDate;
  final String? expiryDate;

  bool get hasExpiry => expiryDate != null && expiryDate!.isNotEmpty;

  StockBatch copyWith({
    String? id,
    String? stockItemId,
    String? branchId,
    int? onHand,
    String? receivedDate,
    String? expiryDate,
  }) {
    return StockBatch(
      id: id ?? this.id,
      stockItemId: stockItemId ?? this.stockItemId,
      branchId: branchId ?? this.branchId,
      onHand: onHand ?? this.onHand,
      receivedDate: receivedDate ?? this.receivedDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      id: json['id'] as String,
      stockItemId: json['stockItemId'] as String,
      branchId: json['branchId'] as String,
      onHand: json['onHand'] as int,
      receivedDate: json['receivedDate'] as String,
      expiryDate: json['expiryDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stockItemId': stockItemId,
        'branchId': branchId,
        'onHand': onHand,
        'receivedDate': receivedDate,
        'expiryDate': expiryDate,
      };

  @override
  List<Object?> get props => [id, stockItemId, branchId, onHand, receivedDate, expiryDate];
}
