import 'package:modular_pos/features/auth/data/dto/auth_user_dto.dart';
import 'package:modular_pos/features/auth/data/dto/tenant_membership_dto.dart';

class TenantSelectionRequiredDto {
  const TenantSelectionRequiredDto({
    required this.selectionToken,
    required this.memberships,
  });

  final String selectionToken;
  final List<TenantMembershipDto> memberships;
}

class EstablishedAuthSessionDto {
  const EstablishedAuthSessionDto({
    required this.user,
    required this.memberships,
    required this.activeTenantId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  final AuthUserDto user;
  final List<TenantMembershipDto> memberships;
  final String? activeTenantId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
}

class AuthLoginResponseDto {
  const AuthLoginResponseDto({
    required this.tenantSelection,
    required this.established,
  });

  final TenantSelectionRequiredDto? tenantSelection;
  final EstablishedAuthSessionDto? established;

  bool get requiresTenantSelection => tenantSelection != null;
}
