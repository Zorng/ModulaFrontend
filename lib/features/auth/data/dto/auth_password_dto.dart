class AuthPasswordResetRequestResultDto {
  const AuthPasswordResetRequestResultDto({required this.expiresInMinutes});

  final int expiresInMinutes;

  factory AuthPasswordResetRequestResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final minutes = json['expiresInMinutes'];
    return AuthPasswordResetRequestResultDto(
      expiresInMinutes: minutes is num ? minutes.toInt() : 0,
    );
  }
}

class AuthPasswordResetConfirmResultDto {
  const AuthPasswordResetConfirmResultDto({required this.reset});

  final bool reset;

  factory AuthPasswordResetConfirmResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthPasswordResetConfirmResultDto(reset: json['reset'] == true);
  }
}
