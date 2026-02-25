class CurrentTenantProfileDto {
  const CurrentTenantProfileDto({
    required this.tenantId,
    required this.tenantName,
    required this.tenantAddress,
    required this.contactNumber,
    required this.logoUrl,
    required this.status,
  });

  final String tenantId;
  final String tenantName;
  final String? tenantAddress;
  final String? contactNumber;
  final String? logoUrl;
  final String status;

  factory CurrentTenantProfileDto.fromJson(Map<String, dynamic> json) {
    String? nullableString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return null;
      return text;
    }

    return CurrentTenantProfileDto(
      tenantId: json['tenantId']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? '',
      tenantAddress: nullableString(json['tenantAddress']),
      contactNumber: nullableString(json['contactNumber']),
      logoUrl: nullableString(json['logoUrl']),
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantAddress': tenantAddress,
      'contactNumber': contactNumber,
      'logoUrl': logoUrl,
      'status': status,
    };
  }
}
