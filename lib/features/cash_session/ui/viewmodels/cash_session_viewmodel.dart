import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

enum SessionStatus { notStarted, open, closed, forceClosed }

class CashSessionState {
  static const _unset = Object();

  const CashSessionState({
    this.session,
    this.movements = const [],
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.canForceClose = false,
  });

  final CashSession? session;
  final List<CashMovement> movements;
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
  double get totalPaidIn => movements
      .where((movement) => movement.movementType == CashMovementTypes.manualIn)
      .fold<double>(0, (sum, movement) => sum + movement.amountUsd);
  double get totalPaidOut => movements
      .where((movement) => movement.movementType == CashMovementTypes.manualOut)
      .fold<double>(0, (sum, movement) => sum + movement.amountUsd);
  bool get hasCashMovement => movements.isNotEmpty;
  String? get sessionId => session?.id;

  CashSessionState copyWith({
    Object? session = _unset,
    Object? movements = _unset,
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    bool? canForceClose,
  }) {
    return CashSessionState(
      session: identical(session, _unset)
          ? this.session
          : session as CashSession?,
      movements: identical(movements, _unset)
          ? this.movements
          : List<CashMovement>.unmodifiable(
              List<CashMovement>.from(movements as List),
            ),
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
    await _fetchActiveSession(loadMovements: true);
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
      await _loadMovements(session.id);
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
    final normalizedType = type.toUpperCase().replaceAll(' ', '_');
    if (normalizedType == 'PAID_IN') {
      await recordPaidIn(
        amountUsd: usdAmount,
        amountKhr: khrAmount,
        reason: reason,
      );
      return;
    }
    if (normalizedType == 'PAID_OUT') {
      await recordPaidOut(
        amountUsd: usdAmount,
        amountKhr: khrAmount,
        reason: reason,
      );
      return;
    }
    await recordAdjustment(
      amountUsdDelta: usdAmount,
      amountKhrDelta: khrAmount,
      reason: reason,
    );
  }

  Future<void> recordPaidIn({
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final trimmedReason = (reason ?? '').trim();
      final safeReason = trimmedReason.length >= 3
          ? trimmedReason
          : 'Manual movement';
      await _movementRepo.recordPaidIn(
        sessionId: sessionId,
        amountUsd: amountUsd,
        amountKhr: amountKhr,
        reason: safeReason,
      );
      await _fetchActiveSession(loadMovements: true);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> recordPaidOut({
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final trimmedReason = (reason ?? '').trim();
      final safeReason = trimmedReason.length >= 3
          ? trimmedReason
          : 'Manual movement';
      await _movementRepo.recordPaidOut(
        sessionId: sessionId,
        amountUsd: amountUsd,
        amountKhr: amountKhr,
        reason: safeReason,
      );
      await _fetchActiveSession(loadMovements: true);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> recordAdjustment({
    required double amountUsdDelta,
    required double amountKhrDelta,
    String? reason,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final trimmedReason = (reason ?? '').trim();
      final safeReason = trimmedReason.length >= 3
          ? trimmedReason
          : 'Manual adjustment';
      await _movementRepo.recordAdjustment(
        sessionId: sessionId,
        amountUsdDelta: amountUsdDelta,
        amountKhrDelta: amountKhrDelta,
        reason: safeReason,
      );
      await _fetchActiveSession(loadMovements: true);
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

  Future<void> _fetchActiveSession({bool loadMovements = false}) async {
    try {
      final active = await _repo.getActiveSession();
      if (active == null || active.id.isEmpty) {
        _clearSession();
        return;
      }
      _applySession(active);
      if (loadMovements) {
        await _loadMovements(active.id);
      }
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _loadMovements(String sessionId) async {
    try {
      final movements = await _movementRepo.listMovements(sessionId: sessionId);
      state = state.copyWith(
        isLoading: false,
        movements: movements,
        error: null,
        errorCode: null,
        canForceClose: _canForceClose(state.session),
      );
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
      movements: const <CashMovement>[],
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
