class PolicyBundleDto {
  const PolicyBundleDto({
    required this.sales,
    required this.inventory,
    required this.cashSession,
    required this.attendance,
  });

  final SalesPolicyDto sales;
  final InventoryPolicyDto inventory;
  final CashSessionPolicyDto cashSession;
  final AttendancePolicyDto attendance;

  factory PolicyBundleDto.fromJson(Map<String, dynamic> payload) {
    final root = _unwrap(payload);

    Map<String, dynamic> pickSection(String key) {
      final value = root[key];
      if (value is Map<String, dynamic>) return value;
      return root;
    }

    final sales = SalesPolicyDto.fromJson(pickSection('sales'));
    final inventory = InventoryPolicyDto.fromJson(pickSection('inventory'));

    final cashRoot =
        (root['cashSession'] is Map<String, dynamic>)
            ? root['cashSession'] as Map<String, dynamic>
            : (root['cash'] is Map<String, dynamic>)
                ? root['cash'] as Map<String, dynamic>
                : root;
    final cashSession = CashSessionPolicyDto.fromJson(cashRoot);

    final attendance = AttendancePolicyDto.fromJson(pickSection('attendance'));

    return PolicyBundleDto(
      sales: sales,
      inventory: inventory,
      cashSession: cashSession,
      attendance: attendance,
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}

class SalesPolicyDto {
  const SalesPolicyDto({
    required this.saleVatEnabled,
    required this.saleVatRatePercent,
    required this.saleFxRateKhrPerUsd,
    required this.saleKhrRoundingEnabled,
    required this.saleKhrRoundingMode,
    required this.saleKhrRoundingGranularity,
  });

  final bool saleVatEnabled;
  final double saleVatRatePercent;
  final double saleFxRateKhrPerUsd;
  final bool saleKhrRoundingEnabled;
  final String saleKhrRoundingMode;
  final String saleKhrRoundingGranularity;

  factory SalesPolicyDto.fromJson(Map<String, dynamic> json) {
    return SalesPolicyDto(
      saleVatEnabled: (json['saleVatEnabled'] as bool?) ?? false,
      saleVatRatePercent:
          (json['saleVatRatePercent'] as num?)?.toDouble() ?? 0,
      saleFxRateKhrPerUsd:
          (json['saleFxRateKhrPerUsd'] as num?)?.toDouble() ?? 4100,
      saleKhrRoundingEnabled:
          (json['saleKhrRoundingEnabled'] as bool?) ?? false,
      saleKhrRoundingMode: json['saleKhrRoundingMode']?.toString() ?? 'NEAREST',
      saleKhrRoundingGranularity:
          json['saleKhrRoundingGranularity']?.toString() ?? '100',
    );
  }
}

class InventoryPolicyDto {
  const InventoryPolicyDto({
    required this.inventoryAutoSubtractOnSale,
    required this.inventoryExpiryTrackingEnabled,
  });

  final bool inventoryAutoSubtractOnSale;
  final bool inventoryExpiryTrackingEnabled;

  factory InventoryPolicyDto.fromJson(Map<String, dynamic> json) {
    return InventoryPolicyDto(
      inventoryAutoSubtractOnSale:
          (json['inventoryAutoSubtractOnSale'] as bool?) ?? false,
      inventoryExpiryTrackingEnabled:
          (json['inventoryExpiryTrackingEnabled'] as bool?) ?? false,
    );
  }
}

class CashSessionPolicyDto {
  const CashSessionPolicyDto({
    required this.cashAllowPaidOut,
    required this.cashRequireRefundApproval,
    required this.cashAllowManualAdjustment,
  });

  final bool cashAllowPaidOut;
  final bool cashRequireRefundApproval;
  final bool cashAllowManualAdjustment;

  factory CashSessionPolicyDto.fromJson(Map<String, dynamic> json) {
    return CashSessionPolicyDto(
      cashAllowPaidOut: (json['cashAllowPaidOut'] as bool?) ??
          (json['allowPaidOut'] as bool?) ??
          false,
      cashRequireRefundApproval: (json['cashRequireRefundApproval'] as bool?) ??
          (json['requireRefundApproval'] as bool?) ??
          false,
      cashAllowManualAdjustment: (json['cashAllowManualAdjustment'] as bool?) ??
          (json['allowManualAdjustment'] as bool?) ??
          false,
    );
  }
}

class AttendancePolicyDto {
  const AttendancePolicyDto({
    required this.attendanceAutoFromCashSession,
    required this.attendanceRequireOutOfShiftApproval,
    required this.attendanceEarlyCheckinBufferEnabled,
    required this.attendanceCheckinBufferMinutes,
    required this.attendanceAllowManagerEdits,
  });

  final bool attendanceAutoFromCashSession;
  final bool attendanceRequireOutOfShiftApproval;
  final bool attendanceEarlyCheckinBufferEnabled;
  final int attendanceCheckinBufferMinutes;
  final bool attendanceAllowManagerEdits;

  factory AttendancePolicyDto.fromJson(Map<String, dynamic> json) {
    return AttendancePolicyDto(
      attendanceAutoFromCashSession:
          (json['attendanceAutoFromCashSession'] as bool?) ??
              (json['autoFromCashSession'] as bool?) ??
              false,
      attendanceRequireOutOfShiftApproval:
          (json['attendanceRequireOutOfShiftApproval'] as bool?) ??
              (json['requireOutOfShiftApproval'] as bool?) ??
              false,
      attendanceEarlyCheckinBufferEnabled:
          (json['attendanceEarlyCheckinBufferEnabled'] as bool?) ??
              (json['earlyCheckinBufferEnabled'] as bool?) ??
              false,
      attendanceCheckinBufferMinutes:
          (json['attendanceCheckinBufferMinutes'] as num?)?.toInt() ??
              (json['checkinBufferMinutes'] as num?)?.toInt() ??
              15,
      attendanceAllowManagerEdits:
          (json['attendanceAllowManagerEdits'] as bool?) ??
              (json['allowManagerEdits'] as bool?) ??
              false,
    );
  }
}

