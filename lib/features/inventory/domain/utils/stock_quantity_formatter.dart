class StockQuantityFormatter {
  StockQuantityFormatter({
    required this.baseQty,
    required this.pieceSize,
    required this.baseUnit,
  });

  final int baseQty;
  final int pieceSize;
  final String baseUnit;

  int get pcs => pieceSize <= 0 ? 0 : baseQty ~/ pieceSize;
  int get remainder => pieceSize <= 0 ? baseQty : baseQty % pieceSize;

  String format() {
    if (pieceSize <= 1) {
      return '$baseQty $baseUnit';
    }
    if (pcs > 0 && remainder > 0) {
      return '$pcs pcs + $remainder $baseUnit';
    }
    if (pcs > 0) {
      return '$pcs pcs';
    }
    return '$remainder $baseUnit';
  }
}
