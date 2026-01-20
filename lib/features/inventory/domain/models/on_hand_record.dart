import 'package:equatable/equatable.dart';

class OnHandRecord extends Equatable {
  const OnHandRecord({
    required this.stockItemId,
    required this.branchId,
    required this.onHand,
    required this.minThreshold,
  });

  final String stockItemId;
  final String branchId;
  final int? onHand;
  final int? minThreshold;

  @override
  List<Object?> get props => [stockItemId, branchId, onHand, minThreshold];
}

