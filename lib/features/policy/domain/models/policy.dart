class BranchPolicyRoundingModes {
  const BranchPolicyRoundingModes._();

  static const nearest = 'NEAREST';
  static const up = 'UP';
  static const down = 'DOWN';

  static const values = <String>{nearest, up, down};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (values.contains(normalized)) return normalized;
    return nearest;
  }
}

class BranchPolicyRoundingGranularities {
  const BranchPolicyRoundingGranularities._();

  static const hundred = '100';
  static const thousand = '1000';

  static const values = <String>{hundred, thousand};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim();
    if (values.contains(normalized)) return normalized;
    return hundred;
  }

  static double asAmount(String? value) {
    return double.tryParse(normalize(value)) ?? 100;
  }
}

class BranchPolicy {
  const BranchPolicy({
    this.tenantId = '',
    this.branchId = '',
    this.saleVatEnabled = false,
    this.saleVatRatePercent = 0,
    this.saleFxRateKhrPerUsd = 4100,
    this.saleKhrRoundingEnabled = false,
    this.saleKhrRoundingMode = BranchPolicyRoundingModes.nearest,
    this.saleKhrRoundingGranularity = BranchPolicyRoundingGranularities.hundred,
    this.saleAllowPayLater = false,
    this.saleAllowManualExternalPaymentClaim = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String tenantId;
  final String branchId;
  final bool saleVatEnabled;
  final double saleVatRatePercent;
  final double saleFxRateKhrPerUsd;
  final bool saleKhrRoundingEnabled;
  final String saleKhrRoundingMode; // NEAREST | UP | DOWN
  final String saleKhrRoundingGranularity; // "100" | "1000"
  final bool saleAllowPayLater;
  final bool saleAllowManualExternalPaymentClaim;
  final String createdAt;
  final String updatedAt;

  BranchPolicy copyWith({
    String? tenantId,
    String? branchId,
    bool? saleVatEnabled,
    double? saleVatRatePercent,
    double? saleFxRateKhrPerUsd,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
    bool? saleAllowPayLater,
    bool? saleAllowManualExternalPaymentClaim,
    String? createdAt,
    String? updatedAt,
  }) {
    return BranchPolicy(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      saleVatEnabled: saleVatEnabled ?? this.saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent ?? this.saleVatRatePercent,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd ?? this.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled:
          saleKhrRoundingEnabled ?? this.saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode == null
          ? this.saleKhrRoundingMode
          : BranchPolicyRoundingModes.normalize(saleKhrRoundingMode),
      saleKhrRoundingGranularity: saleKhrRoundingGranularity == null
          ? this.saleKhrRoundingGranularity
          : BranchPolicyRoundingGranularities.normalize(
              saleKhrRoundingGranularity,
            ),
      saleAllowPayLater: saleAllowPayLater ?? this.saleAllowPayLater,
      saleAllowManualExternalPaymentClaim:
          saleAllowManualExternalPaymentClaim ??
          this.saleAllowManualExternalPaymentClaim,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
