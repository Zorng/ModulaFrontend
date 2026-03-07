import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';

class AuthSession {
  static const Object _unset = Object();

  const AuthSession({
    required this.user,
    required this.memberships,
    required this.activeTenantId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    this.tenantSelectionToken = '',
  });

  final User user;
  final List<TenantMembership> memberships;
  final String? activeTenantId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final String tenantSelectionToken;

  String get establishedTenantId {
    final sessionTenantId = (activeTenantId ?? '').trim();
    if (sessionTenantId.isNotEmpty) return sessionTenantId;
    return user.tenantId.trim();
  }

  bool get hasEstablishedTenantContext =>
      tenantSelectionToken.trim().isEmpty && establishedTenantId.isNotEmpty;

  bool get requiresTenantSelection => !hasEstablishedTenantContext;

  bool get isAccessTokenExpired => DateTime.now().isAfter(accessTokenExpiresAt);

  bool get isRefreshTokenExpired =>
      DateTime.now().isAfter(refreshTokenExpiresAt);

  /// Snapshot for client-side persistence.
  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': user.id,
        'name': user.name,
        'role': user.role,
        'tenantId': user.tenantId,
        'phone': user.phone,
        'status': user.status,
        'branches': user.branches.map((b) => b.toJson()).toList(),
      },
      'memberships': memberships.map((m) => m.toJson()).toList(growable: false),
      'activeTenantId': activeTenantId,
      'tenantSelectionToken': tenantSelectionToken,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
      'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final memberships =
        (json['memberships'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(TenantMembership.fromJson)
            .toList(growable: false) ??
        const <TenantMembership>[];

    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      memberships: memberships,
      activeTenantId: json['activeTenantId']?.toString(),
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ).toUtc(),
      refreshTokenExpiresAt: DateTime.parse(
        json['refreshTokenExpiresAt'] as String,
      ).toUtc(),
      tenantSelectionToken: json['tenantSelectionToken']?.toString() ?? '',
    );
  }

  AuthSession copyWith({
    User? user,
    List<TenantMembership>? memberships,
    Object? activeTenantId = _unset,
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
    Object? tenantSelectionToken = _unset,
  }) {
    return AuthSession(
      user: user ?? this.user,
      memberships: memberships ?? this.memberships,
      activeTenantId: identical(activeTenantId, _unset)
          ? this.activeTenantId
          : activeTenantId as String?,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      tenantSelectionToken: identical(tenantSelectionToken, _unset)
          ? this.tenantSelectionToken
          : tenantSelectionToken as String,
    );
  }
}
