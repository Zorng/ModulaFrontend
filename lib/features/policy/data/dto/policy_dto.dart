import 'package:modular_pos/features/policy/domain/models/policy.dart';

class BranchPolicyDto {
  const BranchPolicyDto({
    required this.tenantId,
    required this.branchId,
    required this.saleVatEnabled,
    required this.saleVatRatePercent,
    required this.saleFxRateKhrPerUsd,
    required this.saleKhrRoundingEnabled,
    required this.saleKhrRoundingMode,
    required this.saleKhrRoundingGranularity,
    required this.saleAllowPayLater,
    required this.createdAt,
    required this.updatedAt,
  });

  final String tenantId;
  final String branchId;
  final bool saleVatEnabled;
  final double saleVatRatePercent;
  final double saleFxRateKhrPerUsd;
  final bool saleKhrRoundingEnabled;
  final String saleKhrRoundingMode;
  final String saleKhrRoundingGranularity;
  final bool saleAllowPayLater;
  final String createdAt;
  final String updatedAt;

  factory BranchPolicyDto.fromJson(Map<String, dynamic> payload) {
    final root = _unwrap(payload);
    return BranchPolicyDto(
      tenantId: root['tenantId']?.toString() ?? '',
      branchId: root['branchId']?.toString() ?? '',
      saleVatEnabled: (root['saleVatEnabled'] as bool?) ?? false,
      saleVatRatePercent:
          (root['saleVatRatePercent'] as num?)?.toDouble() ?? 0,
      saleFxRateKhrPerUsd:
          (root['saleFxRateKhrPerUsd'] as num?)?.toDouble() ?? 4100,
      saleKhrRoundingEnabled:
          (root['saleKhrRoundingEnabled'] as bool?) ?? false,
      saleKhrRoundingMode: BranchPolicyRoundingModes.normalize(
        root['saleKhrRoundingMode']?.toString(),
      ),
      saleKhrRoundingGranularity: BranchPolicyRoundingGranularities.normalize(
        root['saleKhrRoundingGranularity']?.toString(),
      ),
      saleAllowPayLater: (root['saleAllowPayLater'] as bool?) ?? false,
      createdAt: root['createdAt']?.toString() ?? '',
      updatedAt: root['updatedAt']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}

class UpdateBranchPolicyInputDto {
  const UpdateBranchPolicyInputDto({
    this.saleVatEnabled,
    this.saleVatRatePercent,
    this.saleFxRateKhrPerUsd,
    this.saleKhrRoundingEnabled,
    this.saleKhrRoundingMode,
    this.saleKhrRoundingGranularity,
    this.saleAllowPayLater,
  });

  final bool? saleVatEnabled;
  final double? saleVatRatePercent;
  final double? saleFxRateKhrPerUsd;
  final bool? saleKhrRoundingEnabled;
  final String? saleKhrRoundingMode;
  final String? saleKhrRoundingGranularity;
  final bool? saleAllowPayLater;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (saleVatEnabled != null) 'saleVatEnabled': saleVatEnabled,
      if (saleVatRatePercent != null)
        'saleVatRatePercent': saleVatRatePercent,
      if (saleFxRateKhrPerUsd != null)
        'saleFxRateKhrPerUsd': saleFxRateKhrPerUsd,
      if (saleKhrRoundingEnabled != null)
        'saleKhrRoundingEnabled': saleKhrRoundingEnabled,
      if (saleKhrRoundingMode != null)
        'saleKhrRoundingMode': BranchPolicyRoundingModes.normalize(
          saleKhrRoundingMode,
        ),
      if (saleKhrRoundingGranularity != null)
        'saleKhrRoundingGranularity':
            BranchPolicyRoundingGranularities.normalize(
              saleKhrRoundingGranularity,
            ),
      if (saleAllowPayLater != null) 'saleAllowPayLater': saleAllowPayLater,
    };
  }
}
