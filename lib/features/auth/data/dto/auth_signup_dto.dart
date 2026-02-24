class AuthRegisterResultDto {
  const AuthRegisterResultDto({
    required this.accountId,
    required this.phone,
    required this.phoneVerified,
    required this.completedExistingInviteAccount,
  });

  final String accountId;
  final String phone;
  final bool phoneVerified;
  final bool completedExistingInviteAccount;

  factory AuthRegisterResultDto.fromJson(Map<String, dynamic> json) {
    return AuthRegisterResultDto(
      accountId: json['accountId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      phoneVerified: json['phoneVerified'] == true,
      completedExistingInviteAccount:
          json['completedExistingInviteAccount'] == true,
    );
  }
}

class AuthOtpSendResultDto {
  const AuthOtpSendResultDto({required this.expiresInMinutes});

  final int expiresInMinutes;

  factory AuthOtpSendResultDto.fromJson(Map<String, dynamic> json) {
    final minutes = json['expiresInMinutes'];
    return AuthOtpSendResultDto(
      expiresInMinutes: minutes is num ? minutes.toInt() : 0,
    );
  }
}

class AuthOtpVerifyResultDto {
  const AuthOtpVerifyResultDto({required this.verified});

  final bool verified;

  factory AuthOtpVerifyResultDto.fromJson(Map<String, dynamic> json) {
    return AuthOtpVerifyResultDto(verified: json['verified'] == true);
  }
}
