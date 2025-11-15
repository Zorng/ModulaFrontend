import 'package:modular_pos/features/auth/domain/models/user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;

  bool get isAccessTokenExpired =>
      DateTime.now().isAfter(accessTokenExpiresAt);

  bool get isRefreshTokenExpired =>
      DateTime.now().isAfter(refreshTokenExpiresAt);

  /// Snapshot for client-side persistence.
  ///
  /// Note: Deliberately excludes access/refresh token values; those should
  /// be held in memory or httpOnly cookies, not in app storage.
  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': user.id,
        'name': user.name,
        'role': user.role,
      },
      'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
      'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: '',
      refreshToken: '',
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ).toUtc(),
      refreshTokenExpiresAt: DateTime.parse(
        json['refreshTokenExpiresAt'] as String,
      ).toUtc(),
    );
  }
}
