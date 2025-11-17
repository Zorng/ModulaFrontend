import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

const _useMockRepository = true;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_useMockRepository) {
    return MockAuthRepository();
  }

  final api = ref.read(authApiProvider);
  return RemoteAuthRepository(api);
});

abstract class AuthRepository {
  Future<AuthSession> login(String username, String password);
}

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api);

  final AuthApi _api;

  @override
  Future<AuthSession> login(String username, String password) async {
    final user = await _api.login(username: username, password: password);
    final now = DateTime.now().toUtc();

    // TODO: replace placeholder tokens once backend is ready.
    return AuthSession(
      user: user,
      accessToken: 'todo-access-token',
      refreshToken: 'todo-refresh-token',
      accessTokenExpiresAt: now.add(const Duration(minutes: 15)),
      refreshTokenExpiresAt: now.add(const Duration(hours: 72)),
    );
  }
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository() : _records = _parseMockData();

  final List<_MockLoginRecord> _records;

  @override
  Future<AuthSession> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final record = _records.firstWhere(
      (record) =>
          record.username.toLowerCase() == username.toLowerCase() &&
          record.password == password,
      orElse: () => throw Exception('Invalid credentials'),
    );

    final now = DateTime.now().toUtc();

    return AuthSession(
      user: record.user,
      accessToken: record.accessToken,
      refreshToken: record.refreshToken,
      accessTokenExpiresAt: now.add(
        Duration(seconds: record.accessTokenTtlSeconds),
      ),
      refreshTokenExpiresAt: now.add(
        Duration(hours: record.refreshTokenTtlHours),
      ),
    );
  }

  static List<_MockLoginRecord> _parseMockData() {
    final List<dynamic> decoded = jsonDecode(_mockLoginData) as List<dynamic>;
    return decoded
        .map(
          (entry) => _MockLoginRecord.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

class _MockLoginRecord {
  const _MockLoginRecord({
    required this.username,
    required this.password,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenTtlSeconds,
    required this.refreshTokenTtlHours,
  });

  final String username;
  final String password;
  final User user;
  final String accessToken;
  final String refreshToken;
  final int accessTokenTtlSeconds;
  final int refreshTokenTtlHours;

  factory _MockLoginRecord.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>? ?? const {};

    return _MockLoginRecord(
      username: json['username'] as String,
      password: json['password'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: tokens['accessToken'] as String? ?? '',
      refreshToken: tokens['refreshToken'] as String? ?? '',
      accessTokenTtlSeconds: tokens['accessTokenTtlSeconds'] as int? ?? 900,
      refreshTokenTtlHours: tokens['refreshTokenTtlHours'] as int? ?? 72,
    );
  }
}

const _mockLoginData = '''
[
  {
    "username": "cashier@modula.app",
    "password": "password123",
    "tokens": {
      "accessToken": "cashier-access-token",
      "refreshToken": "cashier-refresh-token",
      "accessTokenTtlSeconds": 900,
      "refreshTokenTtlHours": 72
    },
    "user": {
      "id": "user_cashier_1",
      "name": "Demo Cashier",
      "role": "cashier",
      "tenantId": "tenant_demo",
      "branches": [
        {"id": "branch_1", "name": "Main Branch"}
      ]
    }
  },
  {
    "username": "manager@modula.app",
    "password": "password123",
    "tokens": {
      "accessToken": "manager-access-token",
      "refreshToken": "manager-refresh-token",
      "accessTokenTtlSeconds": 900,
      "refreshTokenTtlHours": 72
    },
    "user": {
      "id": "user_manager_1",
      "name": "Demo Manager",
      "role": "manager",
      "tenantId": "tenant_demo",
      "branches": [
        {"id": "branch_1", "name": "Main Branch"}
      ]
    }
  },
  {
    "username": "admin@modula.app",
    "password": "adminStrongPass!",
    "tokens": {
      "accessToken": "admin-access-token",
      "refreshToken": "admin-refresh-token",
      "accessTokenTtlSeconds": 900,
      "refreshTokenTtlHours": 72
    },
    "user": {
      "id": "user_admin_1",
      "name": "Tenant Admin",
      "role": "admin",
      "tenantId": "tenant_demo",
      "branches": [
        {"id": "branch_1", "name": "Main Branch"},
        {"id": "branch_2", "name": "Downtown"},
        {"id": "branch_3", "name": "Airport"}
      ]
    }
  },
  {
    "username": "admin@tenantb.app",
    "password": "password123",
    "tokens": {
      "accessToken": "tenantb-admin-access-token",
      "refreshToken": "tenantb-admin-refresh-token",
      "accessTokenTtlSeconds": 900,
      "refreshTokenTtlHours": 72
    },
    "user": {
      "id": "user_admin_b_1",
      "name": "Tenant B Admin",
      "role": "admin",
      "tenantId": "tenant_b",
      "branches": [
        {"id": "branch_b1", "name": "North"}
      ]
    }
  },
  {
    "username": "cashier@tenantb.app",
    "password": "password123",
    "tokens": {
      "accessToken": "tenantb-cashier-access-token",
      "refreshToken": "tenantb-cashier-refresh-token",
      "accessTokenTtlSeconds": 900,
      "refreshTokenTtlHours": 72
    },
    "user": {
      "id": "user_cashier_b_1",
      "name": "Tenant B Cashier",
      "role": "cashier",
      "tenantId": "tenant_b",
      "branches": [
        {"id": "branch_b1", "name": "North"}
      ]
    }
  }
]
''';
