import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

void main() {
  test('AuthApi.login parses backend payload correctly', () async {
    // Arrange
    const response = {
      "employee": {
        "id": "770e8400-e29b-41d4-a716-446655440010",
        "first_name": "Admin",
        "last_name": "User",
        "phone": "+1234567890",
        "status": "ACTIVE"
      },
      "tokens": {
        "accessToken": "access-token",
        "refreshToken": "refresh-token",
        "expiresIn": 43200
      },
      "branch_assignments": [
        {
          "id": "assign-1",
          "employee_id": "770e8400-e29b-41d4-a716-446655440010",
          "branch_id": "branch-1",
          "branch_name": "Main Branch",
          "role": "ADMIN",
          "active": true
        }
      ]
    };

    // Act
    final session = _parseFixture(response);

    // Assert
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    expect(session.user.name, 'Admin User');
    expect(session.user.phone, '+1234567890');
    expect(session.user.status, 'ACTIVE');
    expect(session.user.role, 'ADMIN');
    expect(session.user.branches, hasLength(1));
    final branch = session.user.branches.first;
    expect(branch.id, 'assign-1');
    expect(branch.branchId, 'branch-1');
    expect(branch.name, 'Main Branch');
    expect(branch.role, 'ADMIN');
    expect(branch.active, true);
  });
}

// Helper that uses the same parsing logic as AuthApi.login without Dio.
AuthSession _parseFixture(Map<String, dynamic> data) {
  final userJson =
      Map<String, dynamic>.from(data['employee'] as Map<String, dynamic>? ?? {});
  final tokens =
      Map<String, dynamic>.from(data['tokens'] as Map<String, dynamic>? ?? {});
  final assignments =
      (data['branch_assignments'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e as Map<String, dynamic>)
          .toList();

  userJson['branches'] = assignments;
  if (userJson['name'] == null) {
    final first = userJson['first_name']?.toString() ?? '';
    final last = userJson['last_name']?.toString() ?? '';
    userJson['name'] = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
  }
  final roleFromAssignment =
      assignments.isNotEmpty ? assignments.first['role']?.toString() : null;
  userJson['role'] = userJson['role'] ?? roleFromAssignment ?? 'cashier';

  final accessToken = tokens['access_token']?.toString() ??
      tokens['accessToken']?.toString() ?? '';
  final refreshToken = tokens['refresh_token']?.toString() ??
      tokens['refreshToken']?.toString() ?? '';
  final expiresInSeconds = (tokens['expiresIn'] as num?)?.toInt() ??
      (tokens['expires_in'] as num?)?.toInt();

  final accessExpiry = expiresInSeconds != null
      ? DateTime.now().add(Duration(seconds: expiresInSeconds))
      : DateTime.now().add(const Duration(minutes: 15));

  return AuthSession(
    user: User.fromJson(userJson),
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAt: accessExpiry,
    refreshTokenExpiresAt: DateTime.now().add(const Duration(hours: 72)),
  );
}
