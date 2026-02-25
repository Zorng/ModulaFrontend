class BranchAccessibleBranchDto {
  const BranchAccessibleBranchDto({
    required this.branchId,
    required this.tenantId,
    required this.branchName,
    required this.branchAddress,
    required this.contactNumber,
    required this.khqrReceiverAccountId,
    required this.khqrReceiverName,
    required this.status,
  });

  final String branchId;
  final String tenantId;
  final String branchName;
  final String? branchAddress;
  final String? contactNumber;
  final String? khqrReceiverAccountId;
  final String? khqrReceiverName;
  final String status;

  factory BranchAccessibleBranchDto.fromJson(Map<String, dynamic> json) {
    return BranchAccessibleBranchDto(
      branchId: json['branchId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      branchAddress: _nullableString(json['branchAddress']),
      contactNumber: _nullableString(json['contactNumber']),
      khqrReceiverAccountId: _nullableString(json['khqrReceiverAccountId']),
      khqrReceiverName: _nullableString(json['khqrReceiverName']),
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'branchId': branchId,
      'tenantId': tenantId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'contactNumber': contactNumber,
      'khqrReceiverAccountId': khqrReceiverAccountId,
      'khqrReceiverName': khqrReceiverName,
      'status': status,
    };
  }
}

class BranchContextTokenResultDto {
  const BranchContextTokenResultDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.branchId,
  });

  final String accessToken;
  final String refreshToken;
  final String? tenantId;
  final String? branchId;

  factory BranchContextTokenResultDto.fromJson(Map<String, dynamic> json) {
    final context = json['context'];
    final contextMap = context is Map
        ? context.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return BranchContextTokenResultDto(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tenantId: _nullableString(contextMap['tenantId']),
      branchId: _nullableString(contextMap['branchId']),
    );
  }
}

class BranchActivationInvoiceDto {
  const BranchActivationInvoiceDto({
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

  factory BranchActivationInvoiceDto.fromJson(Map<String, dynamic> json) {
    return BranchActivationInvoiceDto(
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceType: json['invoiceType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      totalAmountUsd: json['totalAmountUsd']?.toString() ?? '',
      issuedAt: _nullableDateTime(json['issuedAt']),
      paidAt: _nullableDateTime(json['paidAt']),
    );
  }
}

class BranchActivationInitiateDto {
  const BranchActivationInitiateDto({
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
  final BranchActivationInvoiceDto invoice;
  final bool created;

  factory BranchActivationInitiateDto.fromJson(Map<String, dynamic> json) {
    final invoiceMap = json['invoice'];
    return BranchActivationInitiateDto(
      draftId: json['draftId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      activationType: json['activationType']?.toString() ?? '',
      draftStatus: json['draftStatus']?.toString() ?? '',
      invoice: BranchActivationInvoiceDto.fromJson(
        invoiceMap is Map
            ? invoiceMap.map((key, value) => MapEntry(key.toString(), value))
            : const <String, dynamic>{},
      ),
      created: _boolFromDynamic(json['created']),
    );
  }
}

class BranchActivationConfirmDto {
  const BranchActivationConfirmDto({
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

  factory BranchActivationConfirmDto.fromJson(Map<String, dynamic> json) {
    return BranchActivationConfirmDto(
      draftId: json['draftId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      activationType: json['activationType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      paymentConfirmationRef: json['paymentConfirmationRef']?.toString() ?? '',
      created: _boolFromDynamic(json['created']),
    );
  }
}

class BranchActivationInitiateRequestDto {
  const BranchActivationInitiateRequestDto({
    required this.branchName,
  });

  final String branchName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'branchName': branchName,
    };
  }
}

class BranchActivationConfirmRequestDto {
  const BranchActivationConfirmRequestDto({
    required this.draftId,
    required this.paymentToken,
  });

  final String draftId;
  final String paymentToken;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'draftId': draftId,
      'paymentToken': paymentToken,
    };
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime? _nullableDateTime(dynamic value) {
  final raw = _nullableString(value);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

bool _boolFromDynamic(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}
