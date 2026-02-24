import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/auth/data/dto/auth_context_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_signup_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_tokens_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_user_dto.dart';
import 'package:modular_pos/features/auth/data/dto/tenant_membership_dto.dart';
import 'package:modular_pos/features/auth/data/dto/user_branch_dto.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.read(dioProvider);
  return AuthApi(dio);
});

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;
  String get _authPrefix => AppEnv.authApiPrefix;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
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

  DateTime _accessTokenExpiry(String accessToken, {int? fallbackSeconds}) {
    final claims = _decodeJwtClaims(accessToken);
    final exp = claims['exp'];
    if (exp is num && exp > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
    }
    if (fallbackSeconds != null && fallbackSeconds > 0) {
      return DateTime.now().toUtc().add(Duration(seconds: fallbackSeconds));
    }
    return DateTime.now().toUtc().add(const Duration(minutes: 15));
  }

  String _claimString(Map<String, dynamic> claims, List<String> keys) {
    for (final key in keys) {
      final value = claims[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  Future<Map<String, dynamic>> _postData(
    String path, {
    Object? data,
    String? accessTokenOverride,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
          headers:
              (accessTokenOverride != null &&
                  accessTokenOverride.trim().isNotEmpty)
              ? {'Authorization': 'Bearer ${accessTokenOverride.trim()}'}
              : null,
        ),
      );
      return ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Auth request failed.',
      );
    }
  }

  Future<Map<String, dynamic>> _getData(
    String path, {
    String? accessTokenOverride,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        options:
            (accessTokenOverride != null &&
                accessTokenOverride.trim().isNotEmpty)
            ? Options(
                headers: {
                  'Authorization': 'Bearer ${accessTokenOverride.trim()}',
                },
              )
            : null,
      );
      return ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Auth request failed.',
      );
    }
  }

  List<TenantMembershipDto> _toMembershipDtosFromContext(
    AuthTenantContextOptionsDto? options,
  ) {
    if (options == null) return const <TenantMembershipDto>[];
    return options.memberships
        .map(
          (m) => TenantMembershipDto(
            tenantId: m.tenantId,
            tenantName: m.tenantName,
            role: m.roleKey,
            branches: const <UserBranchDto>[],
          ),
        )
        .where((m) => m.tenantId.isNotEmpty)
        .toList(growable: false);
  }

  Future<AuthTenantContextOptionsDto?> _safeListTenantContexts(
    String accessToken,
  ) async {
    try {
      return await listTenantContexts(accessTokenOverride: accessToken);
    } catch (_) {
      return null;
    }
  }

  EstablishedAuthSessionDto _parseEstablishedSession(
    Map<String, dynamic> data,
  ) {
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

    final branches = assignments
        .map(UserBranchDto.fromJson)
        .where((b) => b.id.isNotEmpty)
        .toList(growable: false);

    final tokensDto = AuthTokensDto.fromJson(tokens);
    final accessToken = tokensDto.accessToken;
    final refreshToken = tokensDto.refreshToken;
    final expiresInSeconds = tokensDto.expiresInSeconds;

    final accessExpiry = _accessTokenExpiry(
      accessToken,
      fallbackSeconds: expiresInSeconds,
    );

    final claims = accessToken.isEmpty
        ? const <String, dynamic>{}
        : _decodeJwtClaims(accessToken);
    final tenantIdFromToken =
        claims['tenantId']?.toString() ?? claims['tenant_id']?.toString() ?? '';
    final roleFromToken = claims['role']?.toString() ?? '';

    final roleFromAssignment = branches.isNotEmpty ? branches.first.role : null;

    final tenantId =
        (userJson['tenantId']?.toString() ??
                userJson['tenant_id']?.toString() ??
                '')
            .trim()
            .isNotEmpty
        ? (userJson['tenantId']?.toString() ??
                  userJson['tenant_id']?.toString() ??
                  '')
              .trim()
        : tenantIdFromToken;

    final role = (() {
      final jsonRole = (userJson['role']?.toString() ?? '').trim();
      if (jsonRole.isNotEmpty) return jsonRole;
      if (roleFromToken.trim().isNotEmpty) return roleFromToken.trim();
      if ((roleFromAssignment ?? '').trim().isNotEmpty) {
        return roleFromAssignment!.trim();
      }
      return 'cashier';
    })();

    final normalizedUser = Map<String, dynamic>.from(userJson);
    if ((normalizedUser['name']?.toString().trim() ?? '').isEmpty) {
      final first = normalizedUser['first_name']?.toString() ?? '';
      final last = normalizedUser['last_name']?.toString() ?? '';
      normalizedUser['name'] = [
        first,
        last,
      ].where((e) => e.isNotEmpty).join(' ').trim();
    }
    normalizedUser['tenantId'] = tenantId;
    normalizedUser['role'] = role;

    final rawMemberships = data['memberships'];
    final memberships = rawMemberships is List
        ? rawMemberships
              .map(_asMap)
              .map(TenantMembershipDto.fromJson)
              .where((m) => m.tenantId.isNotEmpty)
              .toList(growable: false)
        : const <TenantMembershipDto>[];

    final tenantObject = _asMap(data['tenant']);
    final tenantName =
        data['tenantName']?.toString() ??
        data['tenant_name']?.toString() ??
        normalizedUser['tenantName']?.toString() ??
        normalizedUser['tenant_name']?.toString() ??
        (tenantObject.isNotEmpty ? tenantObject['name']?.toString() : null) ??
        tenantId;

    final fallbackMembership = TenantMembershipDto(
      tenantId: tenantId,
      tenantName: tenantName,
      role: role,
      branches: branches,
    );

    final activeTenantId =
        data['activeTenantId']?.toString() ??
        data['active_tenant_id']?.toString() ??
        (memberships.isNotEmpty ? memberships.first.tenantId : tenantId);

    final refreshExpiry = DateTime.now().add(const Duration(hours: 72));

    return EstablishedAuthSessionDto(
      user: AuthUserDto.fromJson(normalizedUser, branches: branches),
      memberships: memberships.isNotEmpty ? memberships : [fallbackMembership],
      activeTenantId: activeTenantId.isEmpty ? null : activeTenantId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessExpiry,
      refreshTokenExpiresAt: refreshExpiry,
    );
  }

  EstablishedAuthSessionDto _parseV0EstablishedSession({
    required Map<String, dynamic> data,
    required List<TenantMembershipDto> memberships,
    required String? activeTenantId,
  }) {
    final accessToken = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';
    final context = _asMap(data['context']);
    final claims = _decodeJwtClaims(accessToken);
    final role = _claimString(claims, const ['role', 'roleKey']);
    final tokenTenantId = _claimString(claims, const ['tenantId', 'tenant_id']);
    final resolvedTenantId =
        (activeTenantId ?? context['tenantId']?.toString() ?? tokenTenantId)
            .trim();
    final account = _asMap(data['account']);
    final firstName =
        account['firstName']?.toString() ??
        account['first_name']?.toString() ??
        '';
    final lastName =
        account['lastName']?.toString() ??
        account['last_name']?.toString() ??
        '';
    final derivedName =
        account['name']?.toString() ??
        [
          firstName,
          lastName,
        ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final userId =
        account['id']?.toString() ??
        _claimString(claims, const ['sub', 'accountId', 'userId']);

    final userJson = <String, dynamic>{
      'id': userId,
      'name': derivedName.isEmpty ? 'User' : derivedName,
      'phone': account['phone']?.toString() ?? '',
      'status': 'ACTIVE',
      'role': role.isEmpty ? 'cashier' : role,
      'tenantId': resolvedTenantId,
    };

    final resolvedMemberships = memberships.isNotEmpty
        ? memberships
        : (resolvedTenantId.isNotEmpty
              ? <TenantMembershipDto>[
                  TenantMembershipDto(
                    tenantId: resolvedTenantId,
                    tenantName: resolvedTenantId,
                    role: role,
                    branches: const <UserBranchDto>[],
                  ),
                ]
              : const <TenantMembershipDto>[]);

    return EstablishedAuthSessionDto(
      user: AuthUserDto.fromJson(userJson, branches: const <UserBranchDto>[]),
      memberships: resolvedMemberships,
      activeTenantId: resolvedTenantId.isEmpty ? null : resolvedTenantId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: _accessTokenExpiry(accessToken),
      refreshTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(hours: 72),
      ),
    );
  }

  Future<EstablishedAuthSessionDto> _selectTenantLegacy({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) async {
    final path = '$_authPrefix/select-tenant';
    final data = await _postData(
      path,
      data: {
        'selection_token': selectionToken,
        'tenant_id': tenantId,
        if (branchId != null && branchId.trim().isNotEmpty)
          'branch_id': branchId,
      },
    );
    return _parseEstablishedSession(data);
  }

  Future<AuthRegisterResultDto> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) async {
    final data = await _postData(
      '$_authPrefix/register',
      data: {
        'phone': phone,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender,
        if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty)
          'dateOfBirth': dateOfBirth,
      },
    );
    return AuthRegisterResultDto.fromJson(data);
  }

  Future<AuthOtpSendResultDto> sendRegistrationOtp({
    required String phone,
  }) async {
    final data = await _postData(
      '$_authPrefix/otp/send',
      data: {'phone': phone},
    );
    return AuthOtpSendResultDto.fromJson(data);
  }

  Future<AuthOtpVerifyResultDto> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) async {
    final data = await _postData(
      '$_authPrefix/otp/verify',
      data: {'phone': phone, 'otp': otp},
    );
    return AuthOtpVerifyResultDto.fromJson(data);
  }

  Future<AuthLoginResponseDto> login({
    required String username,
    required String password,
  }) async {
    final data = await _postData(
      '$_authPrefix/login',
      data: {'phone': username, 'password': password},
    );

    final requiresTenantSelection =
        data['requires_tenant_selection'] == true ||
        data['requiresTenantSelection'] == true;
    if (requiresTenantSelection) {
      final selectionToken =
          data['selection_token']?.toString() ??
          data['selectionToken']?.toString() ??
          '';
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';

      final rawMemberships = data['memberships'];
      final memberships = rawMemberships is List
          ? rawMemberships
                .map(_asMap)
                .map(TenantMembershipDto.fromJson)
                .where((m) => m.tenantId.isNotEmpty)
                .toList(growable: false)
          : const <TenantMembershipDto>[];

      return AuthLoginResponseDto(
        tenantSelection: TenantSelectionRequiredDto(
          selectionToken: selectionToken,
          memberships: memberships,
          accessToken: accessToken.isEmpty ? null : accessToken,
          refreshToken: refreshToken.isEmpty ? null : refreshToken,
          accessTokenExpiresAt: accessToken.isEmpty
              ? null
              : _accessTokenExpiry(accessToken),
          refreshTokenExpiresAt: refreshToken.isEmpty
              ? null
              : DateTime.now().toUtc().add(const Duration(hours: 72)),
        ),
        established: null,
      );
    }

    final isLegacyEstablished =
        data.containsKey('tokens') ||
        data.containsKey('branch_assignments') ||
        data.containsKey('branchAssignments');
    if (isLegacyEstablished) {
      return AuthLoginResponseDto(
        tenantSelection: null,
        established: _parseEstablishedSession(data),
      );
    }

    final accessToken = data['accessToken']?.toString() ?? '';
    if (accessToken.isEmpty) {
      return AuthLoginResponseDto(
        tenantSelection: null,
        established: _parseEstablishedSession(data),
      );
    }

    final options = await _safeListTenantContexts(accessToken);
    final memberships = _toMembershipDtosFromContext(options);
    final context = _asMap(data['context']);
    final contextTenantId = context['tenantId']?.toString().trim() ?? '';
    final selectedTenantId = options?.selectedTenantId ?? contextTenantId;
    final effectiveTenantId = selectedTenantId.isNotEmpty
        ? selectedTenantId
        : (memberships.length == 1 ? memberships.first.tenantId : '');
    final needsTenantSelection =
        options?.requiresSelection == true ||
        (effectiveTenantId.isEmpty && memberships.length > 1);

    if (needsTenantSelection) {
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final accessToken = data['accessToken']?.toString() ?? '';
      return AuthLoginResponseDto(
        tenantSelection: TenantSelectionRequiredDto(
          selectionToken: 'v0-context-selection',
          memberships: memberships,
          accessToken: accessToken,
          refreshToken: refreshToken.isEmpty ? null : refreshToken,
          accessTokenExpiresAt: accessToken.isEmpty
              ? null
              : _accessTokenExpiry(accessToken),
          refreshTokenExpiresAt: refreshToken.isEmpty
              ? null
              : DateTime.now().toUtc().add(const Duration(hours: 72)),
        ),
        established: null,
      );
    }

    return AuthLoginResponseDto(
      tenantSelection: null,
      established: _parseV0EstablishedSession(
        data: data,
        memberships: memberships,
        activeTenantId: effectiveTenantId.isEmpty ? null : effectiveTenantId,
      ),
    );
  }

  Future<AuthTenantContextOptionsDto> listTenantContexts({
    String? accessTokenOverride,
  }) async {
    final data = await _getData(
      '$_authPrefix/context/tenants',
      accessTokenOverride: accessTokenOverride,
    );
    return AuthTenantContextOptionsDto.fromJson(data);
  }

  Future<AuthContextTokenResultDto> selectTenantContext({
    required String tenantId,
  }) async {
    final data = await _postData(
      '$_authPrefix/context/tenant/select',
      data: {'tenantId': tenantId},
    );
    return AuthContextTokenResultDto.fromJson(data);
  }

  Future<AuthBranchContextOptionsDto> listBranchContexts({
    String? accessTokenOverride,
  }) async {
    final data = await _getData(
      '$_authPrefix/context/branches',
      accessTokenOverride: accessTokenOverride,
    );
    return AuthBranchContextOptionsDto.fromJson(data);
  }

  Future<AuthContextTokenResultDto> selectBranchContext({
    required String branchId,
  }) async {
    final data = await _postData(
      '$_authPrefix/context/branch/select',
      data: {'branchId': branchId},
    );
    return AuthContextTokenResultDto.fromJson(data);
  }

  Future<AuthContextTokenResultDto> refreshSession({
    required String refreshToken,
  }) async {
    final data = await _postData(
      '$_authPrefix/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthContextTokenResultDto.fromJson(data);
  }

  Future<void> logout({required String refreshToken}) async {
    await _postData(
      '$_authPrefix/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<EstablishedAuthSessionDto> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) async {
    final shouldTryLegacy =
        selectionToken.trim().isNotEmpty &&
        !selectionToken.trim().startsWith('v0-');
    if (shouldTryLegacy) {
      try {
        return await _selectTenantLegacy(
          selectionToken: selectionToken,
          tenantId: tenantId,
          branchId: branchId,
        );
      } catch (_) {
        // Fall through to /v0 context-selection flow.
      }
    }

    final selected = await selectTenantContext(tenantId: tenantId);
    final options = await _safeListTenantContexts(selected.accessToken);
    final memberships = _toMembershipDtosFromContext(options);

    final data = <String, dynamic>{
      'accessToken': selected.accessToken,
      'refreshToken': selected.refreshToken,
      'context': {'tenantId': selected.tenantId, 'branchId': selected.branchId},
    };
    return _parseV0EstablishedSession(
      data: data,
      memberships: memberships,
      activeTenantId: selected.tenantId ?? tenantId,
    );
  }
}
