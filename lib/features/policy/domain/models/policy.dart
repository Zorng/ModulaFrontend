class SalesPolicy {
  const SalesPolicy({
    this.saleVatEnabled = false,
    this.saleVatRatePercent = 0,
    this.saleFxRateKhrPerUsd = 4100,
    this.saleKhrRoundingEnabled = false,
    this.saleKhrRoundingMode = 'NEAREST',
    this.saleKhrRoundingGranularity = '100',
  });

  final bool saleVatEnabled;
  final double saleVatRatePercent;
  final double saleFxRateKhrPerUsd;
  final bool saleKhrRoundingEnabled;
  final String saleKhrRoundingMode; // NEAREST | UP | DOWN
  final String saleKhrRoundingGranularity; // "100" | "1000"

  SalesPolicy copyWith({
    bool? saleVatEnabled,
    double? saleVatRatePercent,
    double? saleFxRateKhrPerUsd,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
  }) {
    return SalesPolicy(
      saleVatEnabled: saleVatEnabled ?? this.saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent ?? this.saleVatRatePercent,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd ?? this.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled:
          saleKhrRoundingEnabled ?? this.saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode ?? this.saleKhrRoundingMode,
      saleKhrRoundingGranularity:
          saleKhrRoundingGranularity ?? this.saleKhrRoundingGranularity,
    );
  }

  factory SalesPolicy.fromJson(Map<String, dynamic> json) {
    final src = (json['sales'] is Map<String, dynamic>)
        ? json['sales'] as Map<String, dynamic>
        : json;
    return SalesPolicy(
      saleVatEnabled: (src['saleVatEnabled'] as bool?) ?? false,
      saleVatRatePercent:
          (src['saleVatRatePercent'] as num?)?.toDouble() ?? 0,
      saleFxRateKhrPerUsd:
          (src['saleFxRateKhrPerUsd'] as num?)?.toDouble() ?? 4100,
      saleKhrRoundingEnabled:
          (src['saleKhrRoundingEnabled'] as bool?) ?? false,
      saleKhrRoundingMode: src['saleKhrRoundingMode']?.toString() ?? 'NEAREST',
      saleKhrRoundingGranularity:
          src['saleKhrRoundingGranularity']?.toString() ?? '100',
    );
  }
}

class InventoryPolicy {
  const InventoryPolicy({
    this.inventoryAutoSubtractOnSale = false,
    this.inventoryExpiryTrackingEnabled = false,
  });

  final bool inventoryAutoSubtractOnSale;
  final bool inventoryExpiryTrackingEnabled;

  InventoryPolicy copyWith({
    bool? inventoryAutoSubtractOnSale,
    bool? inventoryExpiryTrackingEnabled,
  }) {
    return InventoryPolicy(
      inventoryAutoSubtractOnSale:
          inventoryAutoSubtractOnSale ?? this.inventoryAutoSubtractOnSale,
      inventoryExpiryTrackingEnabled:
          inventoryExpiryTrackingEnabled ?? this.inventoryExpiryTrackingEnabled,
    );
  }

  factory InventoryPolicy.fromJson(Map<String, dynamic> json) {
    final src = (json['inventory'] is Map<String, dynamic>)
        ? json['inventory'] as Map<String, dynamic>
        : json;
    return InventoryPolicy(
      inventoryAutoSubtractOnSale:
          (src['inventoryAutoSubtractOnSale'] as bool?) ?? false,
      inventoryExpiryTrackingEnabled:
          (src['inventoryExpiryTrackingEnabled'] as bool?) ?? false,
    );
  }
}

class PolicyBundle {
  const PolicyBundle({
    required this.sales,
    required this.inventory,
  });

  final SalesPolicy sales;
  final InventoryPolicy inventory;
}
