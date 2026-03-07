import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

enum SessionStatus { notStarted, open, closed, forceClosed }

class CashSessionState {
  static const _unset = Object();

  const CashSessionState({
    this.session,
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.canForceClose = false,
  });

  final CashSession? session;
  final bool isLoading;
  final String? error;
  final String? errorCode;
  final bool canForceClose;

  SessionStatus get sessionStatus {
    final currentSession = session;
    if (currentSession == null || currentSession.id.isEmpty) {
      return SessionStatus.notStarted;
    }
    return switch (currentSession.status) {
      CashSessionStatuses.open => SessionStatus.open,
      CashSessionStatuses.closed => SessionStatus.closed,
      CashSessionStatuses.forceClosed => SessionStatus.forceClosed,
      _ => SessionStatus.notStarted,
    };
  }

  DateTime? get startTime => session?.openedAt;
  DateTime? get endTime => session?.closedAt;
  double get openFloatUsd => session?.openingFloatUsd ?? 0;
  double get openFloatKhr => session?.openingFloatKhr ?? 0;
  double get totalPaidIn => session?.totalPaidInUsd ?? 0;
  double get totalPaidOut => session?.totalPaidOutUsd ?? 0;
  bool get hasCashMovement => totalPaidIn > 0 || totalPaidOut > 0;
  String? get sessionId => session?.id;

  CashSessionState copyWith({
    Object? session = _unset,
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    bool? canForceClose,
  }) {
    return CashSessionState(
      session: identical(session, _unset)
          ? this.session
          : session as CashSession?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      canForceClose: canForceClose ?? this.canForceClose,
    );
  }
}

class CashSessionViewModel extends Notifier<CashSessionState> {
  CashSessionRepository get _repo => ref.read(cashSessionRepositoryProvider);
  CashSessionMovementRepository get _movementRepo =>
      ref.read(cashSessionMovementRepositoryProvider);

  @override
  CashSessionState build() {
    ref.watch(
      loginControllerProvider.select(
        (state) => state.session?.accessToken ?? '',
      ),
    );
    ref.watch(authActiveBranchIdProvider);
    return const CashSessionState(isLoading: false);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    await _fetchActiveSession();
  }

  void reset() {
    state = const CashSessionState(isLoading: false);
  }

  Future<void> startSession({
    required double usdAmount,
    required double khrAmount,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final session = await _repo.openSession(
        openingFloatUsd: usdAmount,
        openingFloatKhr: khrAmount,
        note: note,
      );
      _applySession(session);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> addCashMovement(
    String type,
    double usdAmount,
    double khrAmount, {
    String? reason,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final normalizedType = switch (type.toUpperCase().replaceAll(' ', '_')) {
        'PAID_IN' => 'PAID_IN',
        'PAID_OUT' => 'PAID_OUT',
        'ADJUSTMENT' => 'ADJUSTMENT',
        _ => 'PAID_IN',
      };
      final trimmedReason = (reason ?? '').trim();
      final safeReason = trimmedReason.length >= 3
          ? trimmedReason
          : 'Manual movement';
      await _movementRepo.recordMovement(
        sessionId: sessionId,
        type: normalizedType,
        amountUsd: usdAmount,
        amountKhr: khrAmount,
        reason: safeReason,
      );
      await _fetchActiveSession();
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> closeSession({
    required double countedUsd,
    required double countedKhr,
    String? note,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final session = await _repo.closeSession(
        sessionId: sessionId,
        countedCashUsd: countedUsd,
        countedCashKhr: countedKhr,
        note: note,
      );
      _applySession(session);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> forceCloseSession({
    required double countedUsd,
    required double countedKhr,
    required String reason,
    String? note,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final session = await _repo.forceCloseSession(
        sessionId: sessionId,
        countedCashUsd: countedUsd,
        countedCashKhr: countedKhr,
        reason: reason,
        note: note,
      );
      _applySession(session);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _fetchActiveSession() async {
    try {
      final active = await _repo.getActiveSession();
      if (active == null || active.id.isEmpty) {
        _clearSession();
        return;
      }
      _applySession(active);
    } catch (error) {
      _setError(error);
    }
  }

  void _applySession(CashSession session) {
    if (session.id.isEmpty) {
      _clearSession();
      return;
    }

    state = state.copyWith(
      isLoading: false,
      session: session,
      error: null,
      errorCode: null,
      canForceClose: _canForceClose(session),
    );
  }

  void _clearSession() {
    state = state.copyWith(
      isLoading: false,
      session: null,
      error: null,
      errorCode: null,
      canForceClose: false,
    );
  }

  void _setError(Object error) {
    state = state.copyWith(
      isLoading: false,
      error: _errorMessage(error),
      errorCode: _errorCode(error),
      canForceClose: _canForceClose(state.session),
    );
  }

  bool _canForceClose(CashSession? session) {
    if (session == null) return false;
    if (CashSessionStatuses.normalize(session.status) !=
        CashSessionStatuses.open) {
      return false;
    }

    final authRole = resolveSessionAuthRole(
      ref.read(loginControllerProvider).session,
    );
    return authRole == AuthRole.owner ||
        authRole == AuthRole.admin ||
        authRole == AuthRole.manager;
  }

  String _errorMessage(Object error) {
    if (error is ApiClientException) return error.message;
    return error.toString();
  }

  String? _errorCode(Object error) {
    if (error is ApiClientException) return error.code;
    return null;
  }
}

final cashSessionViewModelProvider =
    NotifierProvider<CashSessionViewModel, CashSessionState>(
      CashSessionViewModel.new,
    );
