class BranchListItem {
  const BranchListItem({
    required this.branchId,
    required this.tenantId,
    required this.branchName,
    required this.status,
    this.branchAddress,
    this.contactNumber,
    this.khqrReceiverAccountId,
    this.khqrReceiverName,
    this.attendanceLocationVerificationMode = '',
    this.workplaceLocation,
    this.isNew = false,
    this.shouldHighlight = false,
  });

  final String branchId;
  final String tenantId;
  final String branchName;
  final String status;
  final String? branchAddress;
  final String? contactNumber;
  final String? khqrReceiverAccountId;
  final String? khqrReceiverName;
  final String attendanceLocationVerificationMode;
  final BranchWorkplaceLocation? workplaceLocation;
  final bool isNew;
  final bool shouldHighlight;

  bool get isActive => status == 'ACTIVE';
  bool get isFrozen => status == 'FROZEN';

  BranchListItem copyWith({
    String? branchId,
    String? tenantId,
    String? branchName,
    String? status,
    String? branchAddress,
    String? contactNumber,
    String? khqrReceiverAccountId,
    String? khqrReceiverName,
    String? attendanceLocationVerificationMode,
    BranchWorkplaceLocation? workplaceLocation,
    bool? isNew,
    bool? shouldHighlight,
  }) {
    return BranchListItem(
      branchId: branchId ?? this.branchId,
      tenantId: tenantId ?? this.tenantId,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      branchAddress: branchAddress ?? this.branchAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      khqrReceiverAccountId: khqrReceiverAccountId ?? this.khqrReceiverAccountId,
      khqrReceiverName: khqrReceiverName ?? this.khqrReceiverName,
      attendanceLocationVerificationMode:
          attendanceLocationVerificationMode ??
          this.attendanceLocationVerificationMode,
      workplaceLocation: workplaceLocation ?? this.workplaceLocation,
      isNew: isNew ?? this.isNew,
      shouldHighlight: shouldHighlight ?? this.shouldHighlight,
    );
  }
}

class BranchWorkplaceLocation {
  const BranchWorkplaceLocation({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;

  BranchWorkplaceLocation copyWith({
    double? latitude,
    double? longitude,
    double? radiusMeters,
  }) {
    return BranchWorkplaceLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}

class BranchContextTokens {
  const BranchContextTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.branchId,
  });

  final String accessToken;
  final String refreshToken;
  final String? tenantId;
  final String? branchId;
}

class BranchActivationInvoice {
  const BranchActivationInvoice({
    required this.invoiceId,
    required this.invoiceType,
    required this.status,
    required this.currency,
    required this.totalAmountUsd,
    required this.issuedAt,
    required this.paidAt,
  });

  final String invoiceId;
  final String invoiceType;
  final String status;
  final String currency;
  final String totalAmountUsd;
  final DateTime? issuedAt;
  final DateTime? paidAt;
}

class BranchActivationDraft {
  const BranchActivationDraft({
    required this.draftId,
    required this.tenantId,
    required this.branchName,
    required this.activationType,
    required this.draftStatus,
    required this.invoice,
    required this.created,
  });

  final String draftId;
  final String tenantId;
  final String branchName;
  final String activationType;
  final String draftStatus;
  final BranchActivationInvoice invoice;
  final bool created;
}

class BranchActivationResult {
  const BranchActivationResult({
    required this.draftId,
    required this.branchId,
    required this.tenantId,
    required this.branchName,
    required this.activationType,
    required this.status,
    required this.invoiceId,
    required this.paymentConfirmationRef,
    required this.created,
  });

  final String draftId;
  final String branchId;
  final String tenantId;
  final String branchName;
  final String activationType;
  final String status;
  final String invoiceId;
  final String paymentConfirmationRef;
  final bool created;
}

class BranchTenantAccess {
  const BranchTenantAccess({
    required this.activeTenantId,
    required this.roleKey,
    required this.canManageTenant,
    required this.membershipId,
  });

  final String? activeTenantId;
  final String roleKey;
  final bool canManageTenant;
  final String membershipId;

  bool get hasTenantContext =>
      activeTenantId != null && activeTenantId!.trim().isNotEmpty;
}
