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
    final root = _unwrapPolicyData(json);
    final src = (root['sales'] is Map<String, dynamic>)
        ? root['sales'] as Map<String, dynamic>
        : root;
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
    final root = _unwrapPolicyData(json);
    final src = (root['inventory'] is Map<String, dynamic>)
        ? root['inventory'] as Map<String, dynamic>
        : root;
    return InventoryPolicy(
      inventoryAutoSubtractOnSale:
          (src['inventoryAutoSubtractOnSale'] as bool?) ?? false,
      inventoryExpiryTrackingEnabled:
          (src['inventoryExpiryTrackingEnabled'] as bool?) ?? false,
    );
  }
}

class CashSessionPolicy {
  const CashSessionPolicy({
    this.cashAllowPaidOut = false,
    this.cashRequireRefundApproval = false,
    this.cashAllowManualAdjustment = false,
  });

  final bool cashAllowPaidOut;
  final bool cashRequireRefundApproval;
  final bool cashAllowManualAdjustment;

  CashSessionPolicy copyWith({
    bool? cashAllowPaidOut,
    bool? cashRequireRefundApproval,
    bool? cashAllowManualAdjustment,
  }) {
    return CashSessionPolicy(
      cashAllowPaidOut: cashAllowPaidOut ?? this.cashAllowPaidOut,
      cashRequireRefundApproval:
          cashRequireRefundApproval ?? this.cashRequireRefundApproval,
      cashAllowManualAdjustment:
          cashAllowManualAdjustment ?? this.cashAllowManualAdjustment,
    );
  }

  factory CashSessionPolicy.fromJson(Map<String, dynamic> json) {
    final root = _unwrapPolicyData(json);
    final src = (root['cashSession'] is Map<String, dynamic>)
        ? root['cashSession'] as Map<String, dynamic>
        : (root['cash'] is Map<String, dynamic>)
            ? root['cash'] as Map<String, dynamic>
            : root;

    return CashSessionPolicy(
      cashAllowPaidOut: (src['cashAllowPaidOut'] as bool?) ??
          (src['allowPaidOut'] as bool?) ??
          false,
      cashRequireRefundApproval:
          (src['cashRequireRefundApproval'] as bool?) ??
              (src['requireRefundApproval'] as bool?) ??
              false,
      cashAllowManualAdjustment:
          (src['cashAllowManualAdjustment'] as bool?) ??
              (src['allowManualAdjustment'] as bool?) ??
              false,
    );
  }
}

class AttendancePolicy {
  const AttendancePolicy({
    this.attendanceAutoFromCashSession = false,
    this.attendanceRequireOutOfShiftApproval = false,
    this.attendanceEarlyCheckinBufferEnabled = false,
    this.attendanceCheckinBufferMinutes = 15,
    this.attendanceAllowManagerEdits = false,
  });

  final bool attendanceAutoFromCashSession;
  final bool attendanceRequireOutOfShiftApproval;
  final bool attendanceEarlyCheckinBufferEnabled;
  final int attendanceCheckinBufferMinutes;
  final bool attendanceAllowManagerEdits;

  AttendancePolicy copyWith({
    bool? attendanceAutoFromCashSession,
    bool? attendanceRequireOutOfShiftApproval,
    bool? attendanceEarlyCheckinBufferEnabled,
    int? attendanceCheckinBufferMinutes,
    bool? attendanceAllowManagerEdits,
  }) {
    return AttendancePolicy(
      attendanceAutoFromCashSession:
          attendanceAutoFromCashSession ?? this.attendanceAutoFromCashSession,
      attendanceRequireOutOfShiftApproval: attendanceRequireOutOfShiftApproval ??
          this.attendanceRequireOutOfShiftApproval,
      attendanceEarlyCheckinBufferEnabled:
          attendanceEarlyCheckinBufferEnabled ??
              this.attendanceEarlyCheckinBufferEnabled,
      attendanceCheckinBufferMinutes:
          attendanceCheckinBufferMinutes ?? this.attendanceCheckinBufferMinutes,
      attendanceAllowManagerEdits:
          attendanceAllowManagerEdits ?? this.attendanceAllowManagerEdits,
    );
  }

  factory AttendancePolicy.fromJson(Map<String, dynamic> json) {
    final root = _unwrapPolicyData(json);
    final src = (root['attendance'] is Map<String, dynamic>)
        ? root['attendance'] as Map<String, dynamic>
        : root;
    return AttendancePolicy(
      attendanceAutoFromCashSession:
          (src['attendanceAutoFromCashSession'] as bool?) ??
              (src['autoFromCashSession'] as bool?) ??
              false,
      attendanceRequireOutOfShiftApproval:
          (src['attendanceRequireOutOfShiftApproval'] as bool?) ??
              (src['requireOutOfShiftApproval'] as bool?) ??
              false,
      attendanceEarlyCheckinBufferEnabled:
          (src['attendanceEarlyCheckinBufferEnabled'] as bool?) ??
              (src['earlyCheckinBufferEnabled'] as bool?) ??
              false,
      attendanceCheckinBufferMinutes:
          (src['attendanceCheckinBufferMinutes'] as num?)?.toInt() ??
              (src['checkinBufferMinutes'] as num?)?.toInt() ??
              15,
      attendanceAllowManagerEdits:
          (src['attendanceAllowManagerEdits'] as bool?) ??
              (src['allowManagerEdits'] as bool?) ??
              false,
    );
  }
}

class PolicyBundle {
  const PolicyBundle({
    required this.sales,
    required this.inventory,
    required this.cashSession,
    required this.attendance,
  });

  final SalesPolicy sales;
  final InventoryPolicy inventory;
  final CashSessionPolicy cashSession;
  final AttendancePolicy attendance;
}

Map<String, dynamic> _unwrapPolicyData(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) return data;
  return json;
}
