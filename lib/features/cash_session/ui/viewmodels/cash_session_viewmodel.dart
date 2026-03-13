import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sales_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

enum SessionStatus { notStarted, open, closed, forceClosed }

class CashSessionState {
  static const _unset = Object();
  static const defaultSalesFetchLimit = 20;

  const CashSessionState({
    this.session,
    this.movements = const [],
    this.sales = const [],
    this.hasMoreSales = false,
    this.isLoadingMoreSales = false,
    this.salesFetchLimit = defaultSalesFetchLimit,
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.canForceClose = false,
    this.currentUserAccountId = '',
    this.currentUserRole = AuthRole.unknown,
  });

  final CashSession? session;
  final List<CashMovement> movements;
  final List<CashSessionSale> sales;
  final bool hasMoreSales;
  final bool isLoadingMoreSales;
  final int salesFetchLimit;
  final bool isLoading;
  final String? error;
  final String? errorCode;
  final bool canForceClose;
  final String currentUserAccountId;
  final AuthRole currentUserRole;

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
  bool get hasOpenSession => sessionStatus == SessionStatus.open;
  bool get isOwnedByCurrentUser {
    final openerId = (session?.openedByAccountId ?? '').trim();
    final currentUserId = currentUserAccountId.trim();
    return hasOpenSession &&
        openerId.isNotEmpty &&
        currentUserId.isNotEmpty &&
        openerId == currentUserId;
  }

  bool get isOccupiedByAnotherUser {
    final openerId = (session?.openedByAccountId ?? '').trim();
    final currentUserId = currentUserAccountId.trim();
    return hasOpenSession &&
        openerId.isNotEmpty &&
        currentUserId.isNotEmpty &&
        openerId != currentUserId;
  }

  String? get sessionOwnerLabel {
    if (!hasOpenSession) return null;
    if (isOwnedByCurrentUser) return 'You';
    if (isOccupiedByAnotherUser) {
      final openerName = (session?.openedByName ?? '').trim();
      if (openerName.isNotEmpty) return openerName;
      return 'Another account';
    }
    return null;
  }

  bool get canRecordPaidIn => switch (currentUserRole) {
    AuthRole.cashier ||
    AuthRole.manager ||
    AuthRole.admin ||
    AuthRole.owner => true,
    _ => false,
  };

  bool get canRecordPaidOut => switch (currentUserRole) {
    AuthRole.cashier ||
    AuthRole.manager ||
    AuthRole.admin ||
    AuthRole.owner => true,
    _ => false,
  };

  bool get canRecordAdjustment => switch (currentUserRole) {
    AuthRole.manager || AuthRole.admin || AuthRole.owner => true,
    _ => false,
  };

  bool get canWriteAnyMovement =>
      canRecordPaidIn || canRecordPaidOut || canRecordAdjustment;

  bool canRecordMovementType(String type) {
    final normalizedType = type.trim().toUpperCase().replaceAll(' ', '_');
    return switch (normalizedType) {
      'PAID_IN' => canRecordPaidIn,
      'PAID_OUT' => canRecordPaidOut,
      'ADJUSTMENT' => canRecordAdjustment,
      _ => false,
    };
  }

  CashSessionState copyWith({
    Object? session = _unset,
    Object? movements = _unset,
    Object? sales = _unset,
    bool? hasMoreSales,
    bool? isLoadingMoreSales,
    int? salesFetchLimit,
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    bool? canForceClose,
    String? currentUserAccountId,
    AuthRole? currentUserRole,
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
      sales: identical(sales, _unset)
          ? this.sales
          : List<CashSessionSale>.unmodifiable(
              List<CashSessionSale>.from(sales as List),
            ),
      hasMoreSales: hasMoreSales ?? this.hasMoreSales,
      isLoadingMoreSales: isLoadingMoreSales ?? this.isLoadingMoreSales,
      salesFetchLimit: salesFetchLimit ?? this.salesFetchLimit,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      canForceClose: canForceClose ?? this.canForceClose,
      currentUserAccountId: currentUserAccountId ?? this.currentUserAccountId,
      currentUserRole: currentUserRole ?? this.currentUserRole,
    );
  }
}

class CashSessionViewModel extends Notifier<CashSessionState> {
  CashSessionRepository get _repo => ref.read(cashSessionRepositoryProvider);
  CashSessionMovementRepository get _movementRepo =>
      ref.read(cashSessionMovementRepositoryProvider);
  CashSessionSalesRepository get _salesRepo =>
      ref.read(cashSessionSalesRepositoryProvider);

  @override
  CashSessionState build() {
    final authSession = ref.watch(
      loginControllerProvider.select((state) => state.session),
    );
    final currentUserId = ref.watch(
      loginControllerProvider.select(
        (state) => _resolveCurrentAccountId(state.session),
      ),
    );
    ref.watch(authActiveBranchIdProvider);
    return CashSessionState(
      isLoading: false,
      currentUserAccountId: currentUserId,
      currentUserRole: resolveSessionAuthRole(authSession),
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    await _fetchActiveSession(loadMovements: true, loadSales: true);
  }

  void reset() {
    state = state.copyWith(
      session: null,
      movements: const <CashMovement>[],
      sales: const <CashSessionSale>[],
      hasMoreSales: false,
      isLoadingMoreSales: false,
      isLoading: false,
      error: null,
      errorCode: null,
      canForceClose: false,
    );
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
      await _loadSessionDetails(
        session.id,
        loadMovements: true,
        loadSales: true,
      );
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
      await _fetchActiveSession(loadMovements: true, loadSales: true);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> loadMoreSales() async {
    final sessionId = state.sessionId;
    if (sessionId == null ||
        sessionId.isEmpty ||
        state.isLoadingMoreSales ||
        !state.hasMoreSales) {
      return;
    }

    state = state.copyWith(isLoadingMoreSales: true);
    try {
      final nextPage = await _salesRepo.listSales(
        sessionId: sessionId,
        limit: state.salesFetchLimit,
        offset: state.sales.length,
      );
      final merged = List<CashSessionSale>.from(state.sales)..addAll(nextPage);
      state = state.copyWith(
        sales: merged,
        hasMoreSales: nextPage.length == state.salesFetchLimit,
        isLoadingMoreSales: false,
        error: null,
        errorCode: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMoreSales: false,
        error: _errorMessage(error),
        errorCode: _errorCode(error),
      );
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
      await _fetchActiveSession(loadMovements: true, loadSales: true);
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
      await _fetchActiveSession(loadMovements: true, loadSales: true);
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
      await _repo.closeSession(
        sessionId: sessionId,
        countedCashUsd: countedUsd,
        countedCashKhr: countedKhr,
        note: note,
      );
      await _fetchActiveSession(loadMovements: true, loadSales: true);
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
      await _repo.forceCloseSession(
        sessionId: sessionId,
        countedCashUsd: countedUsd,
        countedCashKhr: countedKhr,
        reason: reason,
        note: note,
      );
      await _fetchActiveSession(loadMovements: true, loadSales: true);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _fetchActiveSession({
    bool loadMovements = false,
    bool loadSales = false,
  }) async {
    try {
      final active = await _repo.getActiveSession();
      if (active == null || active.id.isEmpty) {
        _clearSession();
        return;
      }
      _applySession(active);
      if (loadMovements || loadSales) {
        await _loadSessionDetails(
          active.id,
          loadMovements: loadMovements,
          loadSales: loadSales,
        );
      }
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> _loadSessionDetails(
    String sessionId, {
    required bool loadMovements,
    required bool loadSales,
  }) async {
    try {
      final movementFuture = loadMovements
          ? _movementRepo.listMovements(sessionId: sessionId)
          : Future.value(state.movements);
      final salesFuture = loadSales
          ? _salesRepo.listSales(
              sessionId: sessionId,
              limit: state.salesFetchLimit,
              offset: 0,
            )
          : Future.value(state.sales);
      final results = await Future.wait<Object>([movementFuture, salesFuture]);
      final movements = results[0] as List<CashMovement>;
      final sales = results[1] as List<CashSessionSale>;
      state = state.copyWith(
        isLoading: false,
        movements: movements,
        sales: sales,
        hasMoreSales: loadSales
            ? sales.length == state.salesFetchLimit
            : state.hasMoreSales,
        isLoadingMoreSales: false,
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
      sales: const <CashSessionSale>[],
      hasMoreSales: false,
      isLoadingMoreSales: false,
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
      isLoadingMoreSales: false,
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

  String _resolveCurrentAccountId(session) {
    final accessToken = session?.accessToken?.toString() ?? '';
    final tokenId = _claimString(_decodeJwtClaims(accessToken), const [
      'sub',
      'accountId',
      'userId',
    ]);
    if (tokenId.isNotEmpty) return tokenId;
    return session?.user.id?.toString() ?? '';
  }

  Map<String, dynamic> _decodeJwtClaims(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return const <String, dynamic>{};
    final payload = parts[1].trim();
    if (payload.isEmpty) return const <String, dynamic>{};

    try {
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
      if (json is Map) {
        return json.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }

  String _claimString(Map<String, dynamic> claims, List<String> keys) {
    for (final key in keys) {
      final value = claims[key]?.toString() ?? '';
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}

final cashSessionViewModelProvider =
    NotifierProvider<CashSessionViewModel, CashSessionState>(
      CashSessionViewModel.new,
    );
