class AuthTokensDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  final String accessToken;
  final String refreshToken;
  final int? expiresInSeconds;

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    final accessToken =
        json['access_token']?.toString() ?? json['accessToken']?.toString() ?? '';
    final refreshToken =
        json['refresh_token']?.toString() ?? json['refreshToken']?.toString() ?? '';
    final expires =
        (json['expiresIn'] as num?)?.toInt() ?? (json['expires_in'] as num?)?.toInt();
    return AuthTokensDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expires,
    );
  }
}

