import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_repository_session_utils.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/phone_input.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/tenant/data/tenant_repository.dart';

class LoginState {
  static const Object _unset = Object();

  final bool isLoading;
  final AuthSession? session;
  final String? error;
  final String? errorCode;
  final int? errorStatusCode;
  final String? pendingVerificationPhone;
  final int? otpExpiresInMinutes;
  final List<AuthBranchContextOption> branchOptions;
  final bool requiresBranchSelection;

  const LoginState({
    this.isLoading = false,
    this.session,
    this.error,
    this.errorCode,
    this.errorStatusCode,
    this.pendingVerificationPhone,
    this.otpExpiresInMinutes,
    this.branchOptions = const <AuthBranchContextOption>[],
    this.requiresBranchSelection = false,
  });

  User? get user => session?.user;

  LoginState copyWith({
    bool? isLoading,
    AuthSession? session,
    Object? error = _unset,
    Object? errorCode = _unset,
    Object? errorStatusCode = _unset,
    Object? pendingVerificationPhone = _unset,
    Object? otpExpiresInMinutes = _unset,
    List<AuthBranchContextOption>? branchOptions,
    bool? requiresBranchSelection,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      errorStatusCode: identical(errorStatusCode, _unset)
          ? this.errorStatusCode
          : errorStatusCode as int?,
      pendingVerificationPhone: identical(pendingVerificationPhone, _unset)
          ? this.pendingVerificationPhone
          : pendingVerificationPhone as String?,
      otpExpiresInMinutes: identical(otpExpiresInMinutes, _unset)
          ? this.otpExpiresInMinutes
          : otpExpiresInMinutes as int?,
      branchOptions: branchOptions ?? this.branchOptions,
      requiresBranchSelection:
          requiresBranchSelection ?? this.requiresBranchSelection,
    );
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  AuthSessionStore get _sessionStore => ref.read(authSessionStoreProvider);
  TenantRepository get _tenantRepository => ref.read(tenantRepositoryProvider);

  @override
  LoginState build() {
    final initialSession = ref.read(initialAuthSessionProvider);
    return LoginState(session: initialSession);
  }

  Future<void> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) async {
    final normalizedPhone = normalizePhoneInput(phone);
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final result = await _repository.registerAccount(
        phone: normalizedPhone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      state = state.copyWith(
        isLoading: false,
        pendingVerificationPhone: result.phone,
      );
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Account registration failed.');
    }
  }

  Future<void> sendRegistrationOtp({required String phone}) async {
    final normalizedPhone = normalizePhoneInput(phone);
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final result = await _repository.sendRegistrationOtp(
        phone: normalizedPhone,
      );
      state = state.copyWith(
        isLoading: false,
        pendingVerificationPhone: normalizedPhone,
        otpExpiresInMinutes: result.expiresInMinutes,
      );
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Failed to send OTP.');
    }
  }

  Future<void> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) async {
    final normalizedPhone = normalizePhoneInput(phone);
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final result = await _repository.verifyRegistrationOtp(
        phone: normalizedPhone,
        otp: otp,
      );
      if (!result.verified) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid verification code.',
          errorCode: 'OTP_INVALID',
          errorStatusCode: 400,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        pendingVerificationPhone: normalizedPhone,
        otpExpiresInMinutes: null,
      );
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Failed to verify OTP.');
    }
  }

  Future<void> login(String username, String password) async {
    final normalizedUsername = normalizePhoneInput(username);
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
      requiresBranchSelection: false,
      branchOptions: const <AuthBranchContextOption>[],
    );

    try {
      final session = _normalizeLoginSession(
        await _repository.login(normalizedUsername, password),
      );
      // Persist snapshot immediately so refresh/reload keeps auth state and
      // routing state (tenant/branch selection steps).
      await _sessionStore.save(session);
      state = state.copyWith(
        isLoading: false,
        session: session,
        requiresBranchSelection: false,
        branchOptions: const <AuthBranchContextOption>[],
      );
    } catch (e, st) {
      if (e is ApiClientException && _isPhoneNotVerified(e)) {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
          errorCode: e.code,
          errorStatusCode: e.statusCode,
          pendingVerificationPhone: normalizedUsername,
        );
        return;
      }
      _setError(e, st, fallbackMessage: 'Login failed.');
    }
  }

  Future<bool> selectTenant(String tenantId) async {
    final current = state.session;
    if (current == null) return false;

    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
      requiresBranchSelection: false,
      branchOptions: const <AuthBranchContextOption>[],
    );

    try {
      final selected = await _repository.selectTenant(
        selectionToken: current.tenantSelectionToken,
        tenantId: tenantId,
      );
      final nextSession = selected.copyWith(
        memberships: selected.memberships.isNotEmpty
            ? selected.memberships
            : current.memberships,
        activeTenantId: tenantId,
        tenantSelectionToken: '',
      );
      final mergedUser = _mergeIdentityFromCurrentUser(
        current.user,
        nextSession.user,
      );
      final tenantRole = _roleForTenant(nextSession.memberships, tenantId);
      final nextSessionWithRole = nextSession.copyWith(
        user: mergedUser.copyWith(tenantId: tenantId, role: tenantRole),
      );
      // Validate tenant context using canonical org endpoint before persisting.
      final tenantProfile = await _tenantRepository.getCurrentTenantProfile(
        accessTokenOverride: nextSessionWithRole.accessToken,
      );
      final resolvedTenantId = tenantProfile.tenantId.trim();
      if (resolvedTenantId.isNotEmpty && resolvedTenantId != tenantId.trim()) {
        throw ApiClientException(
          message: 'Selected tenant context mismatch.',
          code: 'TENANT_CONTEXT_MISMATCH',
          statusCode: 409,
        );
      }
      // Prevent stale branch-local marker from previous tenant context.
      ref.read(authActiveBranchOverrideProvider.notifier).clear();
      ref.read(authActiveBranchNameOverrideProvider.notifier).clear();

      try {
        final branchResolution = await _resolveBranchContextState(
          nextSessionWithRole,
        );
        await _sessionStore.save(branchResolution.session);
        state = state.copyWith(
          isLoading: false,
          session: branchResolution.session,
          requiresBranchSelection: branchResolution.requiresBranchSelection,
          branchOptions: branchResolution.branchOptions,
        );
        return true;
      } catch (error, stackTrace) {
        if (error is ApiClientException &&
            _isRecoverableBranchContextResolutionError(error)) {
          final role = resolveSessionAuthRole(nextSessionWithRole);
          final requiresBranchSelection =
              role == AuthRole.cashier || role == AuthRole.manager;
          AppLog.e(
            'Recoverable branch-context error after tenant selection; '
            'falling back to a context-pending state.',
            error: error,
            stackTrace: stackTrace,
          );
          await _sessionStore.save(nextSessionWithRole);
          state = state.copyWith(
            isLoading: false,
            session: nextSessionWithRole,
            requiresBranchSelection: requiresBranchSelection,
            branchOptions: const <AuthBranchContextOption>[],
            error: null,
            errorCode: null,
            errorStatusCode: null,
          );
          return true;
        }
        rethrow;
      }
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Tenant selection failed.');
      return false;
    }
  }

  Future<void> loadBranchContexts() async {
    final current = state.session;
    if (current == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final options = await _repository.listBranchContexts(
        currentSession: current,
      );
      state = state.copyWith(
        isLoading: false,
        branchOptions: options.branches,
        requiresBranchSelection: options.requiresSelection,
      );
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Failed to load branches.');
    }
  }

  Future<void> selectBranch(String branchId) async {
    final current = state.session;
    if (current == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final selected = await _repository.selectBranch(
        currentSession: current,
        branchId: branchId,
      );
      await _sessionStore.save(selected);
      state = state.copyWith(
        isLoading: false,
        session: selected,
        branchOptions: const <AuthBranchContextOption>[],
        requiresBranchSelection: false,
      );
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Branch selection failed.');
    }
  }

  Future<void> refreshSession() async {
    final current = state.session;
    if (current == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
    );

    try {
      final refreshed = await _repository.refreshSession(
        currentSession: current,
      );
      await _sessionStore.save(refreshed);
      await _applyBranchContextState(refreshed);
    } catch (e, st) {
      _setError(e, st, fallbackMessage: 'Session refresh failed.');
    }
  }

  Future<void> upsertSessionTenantMembership({
    required String tenantId,
    required String tenantName,
    required String role,
    List<UserBranch> branches = const <UserBranch>[],
  }) async {
    final current = state.session;
    if (current == null) return;

    final updated = upsertTenantMembership(
      current,
      tenantId: tenantId,
      tenantName: tenantName,
      role: role,
      branches: branches,
    );
    if (identical(updated, current)) return;

    await _sessionStore.save(updated);
    state = state.copyWith(session: updated);
  }

  /// Used by the network layer for silent token refresh on 401 responses.
  ///
  /// This avoids UI loading/error state churn while still rotating tokens and
  /// invalidating session when refresh is no longer valid.
  Future<AuthSession?> refreshSessionForNetwork() async {
    final current = state.session;
    if (current == null) return null;

    try {
      final refreshed = await _repository.refreshSession(
        currentSession: current,
      );
      await _sessionStore.save(refreshed);
      state = state.copyWith(
        session: refreshed,
        error: null,
        errorCode: null,
        errorStatusCode: null,
      );
      return refreshed;
    } catch (e, st) {
      AppLog.e(
        'Silent refresh failed, clearing session',
        error: e,
        stackTrace: st,
      );
      await _sessionStore.clear();
      state = const LoginState();
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.session?.refreshToken;
    try {
      await _repository.logout(refreshToken: refreshToken);
    } catch (e, st) {
      AppLog.e('Logout failed', error: e, stackTrace: st);
    }
    await _sessionStore.clear();
    ref.read(authActiveBranchOverrideProvider.notifier).clear();
    ref.read(authActiveBranchNameOverrideProvider.notifier).clear();
    state = const LoginState();
  }

  Future<void> _applyBranchContextState(AuthSession session) async {
    final branchResolution = await _resolveBranchContextState(session);
    if (!identical(branchResolution.session, session)) {
      await _sessionStore.save(branchResolution.session);
    }
    state = state.copyWith(
      isLoading: false,
      session: branchResolution.session,
      requiresBranchSelection: branchResolution.requiresBranchSelection,
      branchOptions: branchResolution.branchOptions,
    );
  }

  AuthSession _normalizeLoginSession(AuthSession session) {
    final selectionToken = session.tenantSelectionToken.trim().isNotEmpty
        ? session.tenantSelectionToken.trim()
        : 'v0-context-selection';

    return session.copyWith(
      user: session.user.copyWith(tenantId: '', role: '', branches: const []),
      activeTenantId: null,
      tenantSelectionToken: selectionToken,
    );
  }

  Future<_BranchContextResolution> _resolveBranchContextState(
    AuthSession session,
  ) async {
    final branchContext = await _repository.listBranchContexts(
      currentSession: session,
    );
    final hasActiveBranchContext = (currentBranchId(session) ?? '')
        .trim()
        .isNotEmpty;
    final role = resolveSessionAuthRole(session);
    final isBranchFirstRole =
        role == AuthRole.cashier || role == AuthRole.manager;
    final requiresBranchSelection = isBranchFirstRole
        ? branchContext.requiresSelection || !hasActiveBranchContext
        : false;

    return _BranchContextResolution(
      session: session,
      requiresBranchSelection: requiresBranchSelection,
      branchOptions: branchContext.branches,
    );
  }

  String _roleForTenant(List<TenantMembership> memberships, String tenantId) {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) return '';
    final matched = memberships.where(
      (membership) =>
          membership.tenantId.trim().isNotEmpty &&
          membership.tenantId.trim() == normalizedTenantId,
    );
    if (matched.isEmpty) return '';
    return matched.first.role.trim();
  }

  User _mergeIdentityFromCurrentUser(User currentUser, User selectedUser) {
    final selectedName = selectedUser.name.trim();
    final selectedPhone = selectedUser.phone.trim();
    final selectedId = selectedUser.id.trim();
    final selectedStatus = selectedUser.status.trim();

    final useCurrentName =
        selectedName.isEmpty || selectedName.toLowerCase() == 'user';

    return selectedUser.copyWith(
      id: selectedId.isEmpty ? currentUser.id : selectedUser.id,
      name: useCurrentName ? currentUser.name : selectedUser.name,
      phone: selectedPhone.isEmpty ? currentUser.phone : selectedUser.phone,
      status: selectedStatus.isEmpty ? currentUser.status : selectedUser.status,
    );
  }

  void _setError(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    AppLog.e(fallbackMessage, error: error, stackTrace: stackTrace);
    if (error is ApiClientException) {
      state = state.copyWith(
        isLoading: false,
        error: error.message,
        errorCode: error.code,
        errorStatusCode: error.statusCode,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      error: fallbackMessage,
      errorCode: null,
      errorStatusCode: null,
    );
  }

  bool _isPhoneNotVerified(ApiClientException exception) {
    if (exception.statusCode != 403) return false;
    final code = (exception.code ?? '').trim().toUpperCase();
    final message = exception.message.trim().toUpperCase();
    if (code.contains('PHONE_NOT_VERIFIED')) return true;
    if (message.contains('PHONE NOT VERIFIED')) return true;
    if (message.contains('NOT VERIFIED')) return true;
    return false;
  }

  bool _isRecoverableBranchContextResolutionError(
    ApiClientException exception,
  ) {
    final statusCode = exception.statusCode;
    final code = (exception.code ?? '').trim().toUpperCase();
    final message = exception.message.trim().toUpperCase();

    final isBranchNotFound =
        statusCode == 404 ||
        code.contains('BRANCH_NOT_FOUND') ||
        message.contains('BRANCH NOT FOUND');
    final isBranchAccessError =
        statusCode == 403 &&
        (code.contains('NO_BRANCH_ACCESS') ||
            code.contains('BRANCH_CONTEXT_REQUIRED') ||
            message.contains('NO BRANCH ACCESS') ||
            message.contains('BRANCH CONTEXT REQUIRED'));

    return isBranchNotFound || isBranchAccessError;
  }
}

class _BranchContextResolution {
  const _BranchContextResolution({
    required this.session,
    required this.requiresBranchSelection,
    required this.branchOptions,
  });

  final AuthSession session;
  final bool requiresBranchSelection;
  final List<AuthBranchContextOption> branchOptions;
}
