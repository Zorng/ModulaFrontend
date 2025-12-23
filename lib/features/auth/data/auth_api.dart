import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio);
});

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> body) {
    final safeBody = Map<String, dynamic>.from(body);
    final inner = safeBody['data'];
    if (safeBody['success'] == true && inner is Map) {
      return _asMap(inner);
    }
    return safeBody;
  }

  Map<String, dynamic> _decodeJwtClaims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return const <String, dynamic>{};

    try {
      final payloadPart = parts[1];
      final normalized = base64Url.normalize(payloadPart);
      final decodedJson = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(decodedJson);
      return _asMap(decoded);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  AuthSession _parseEstablishedSession(Map<String, dynamic> data) {
    final userJson = (() {
      final employee = _asMap(data['employee']);
      if (employee.isNotEmpty) return employee;
      final user = _asMap(data['user']);
      if (user.isNotEmpty) return user;
      final account = _asMap(data['account']);
      if (account.isNotEmpty) return account;
      return <String, dynamic>{};
    })();

    final tokens = _asMap(data['tokens']);

    final assignmentsValue =
        data['branch_assignments'] ?? data['branchAssignments'];
    final assignments = assignmentsValue is List
        ? assignmentsValue
            .map(_asMap)
            .where((m) => m.isNotEmpty)
            .toList(growable: false)
        : const <Map<String, dynamic>>[];

    if ((userJson['name']?.toString().trim() ?? '').isEmpty) {
      final first = userJson['first_name']?.toString() ?? '';
      final last = userJson['last_name']?.toString() ?? '';
      userJson['name'] = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    }

    final accessToken =
        tokens['access_token']?.toString() ?? tokens['accessToken']?.toString() ?? '';
    final refreshToken = tokens['refresh_token']?.toString() ??
        tokens['refreshToken']?.toString() ??
        '';
    final expiresInSeconds =
        (tokens['expiresIn'] as num?)?.toInt() ?? (tokens['expires_in'] as num?)?.toInt();

    final accessExpiry = expiresInSeconds != null
        ? DateTime.now().add(Duration(seconds: expiresInSeconds))
        : DateTime.now().add(const Duration(minutes: 15));

    final claims = accessToken.isEmpty ? const <String, dynamic>{} : _decodeJwtClaims(accessToken);
    final tenantIdFromToken =
        claims['tenantId']?.toString() ?? claims['tenant_id']?.toString() ?? '';
    final roleFromToken = claims['role']?.toString() ?? '';

    final roleFromAssignment =
        assignments.isNotEmpty ? assignments.first['role']?.toString() : null;

    final tenantId = (userJson['tenantId']?.toString() ??
            userJson['tenant_id']?.toString() ??
            '')
        .trim()
        .isNotEmpty
        ? (userJson['tenantId']?.toString() ?? userJson['tenant_id']?.toString() ?? '').trim()
        : tenantIdFromToken;

    final role = (() {
      final jsonRole = (userJson['role']?.toString() ?? '').trim();
      if (jsonRole.isNotEmpty) return jsonRole;
      if (roleFromToken.trim().isNotEmpty) return roleFromToken.trim();
      if ((roleFromAssignment ?? '').trim().isNotEmpty) return roleFromAssignment!.trim();
      return 'cashier';
    })();

    userJson['tenantId'] = tenantId;
    userJson['role'] = role;

    final branches = assignments.map(UserBranch.fromJson).toList(growable: false);

    final membership = TenantMembership(
      tenantId: tenantId,
      tenantName: tenantId,
      role: role,
      branches: branches,
    );

    userJson['branches'] =
        branches.map((b) => b.toJson()).toList(growable: false);

    final refreshExpiry = DateTime.now().add(const Duration(hours: 72));

    return AuthSession(
      user: User.fromJson(userJson),
      memberships: [membership],
      activeTenantId: tenantId.isEmpty ? null : tenantId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessExpiry,
      refreshTokenExpiresAt: refreshExpiry,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final authPrefix = dotenv.env['AUTH_API_PREFIX'] ?? '/v1/auth';
    final path = '$authPrefix/login';

    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {
        'phone': username,
        'password': password,
      },
    );

    final data = _unwrap(response.data ?? {});

    final requiresTenantSelection =
        data['requires_tenant_selection'] == true || data['requiresTenantSelection'] == true;
    if (requiresTenantSelection) {
      final selectionToken =
          data['selection_token']?.toString() ?? data['selectionToken']?.toString() ?? '';

      final rawMemberships = data['memberships'];
      final memberships = rawMemberships is List
          ? rawMemberships
              .map(_asMap)
              .map(TenantMembership.fromJson)
              .where((m) => m.tenantId.isNotEmpty)
              .toList(growable: false)
          : const <TenantMembership>[];

      return AuthSession(
        user: User(
          id: '',
          name: '',
          role: '',
          tenantId: '',
        ),
        memberships: memberships,
        activeTenantId: null,
        accessToken: '',
        refreshToken: '',
        accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
        refreshTokenExpiresAt: DateTime.now().add(const Duration(hours: 72)),
        tenantSelectionToken: selectionToken,
      );
    }

    return _parseEstablishedSession(data);
  }

  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) async {
    final authPrefix = dotenv.env['AUTH_API_PREFIX'] ?? '/v1/auth';
    final path = '$authPrefix/select-tenant';

    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {
        'selection_token': selectionToken,
        'tenant_id': tenantId,
        if (branchId != null && branchId.trim().isNotEmpty) 'branch_id': branchId,
      },
    );

    final data = _unwrap(response.data ?? {});
    return _parseEstablishedSession(data);
  }
}
