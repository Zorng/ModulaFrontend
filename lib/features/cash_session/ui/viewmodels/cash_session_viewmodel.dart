import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_register.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

/// Enum to represent the distinct states of a cash session.
enum SessionStatus { notStarted, open, closed }

/// An immutable class that holds the state for a cash session.
class CashSessionState {
  static const _unset = Object();

  const CashSessionState({
    this.sessionStatus = SessionStatus.notStarted,
    this.startTime,
    this.endTime,
    this.openFloatUsd = 0,
    this.openFloatKhr = 0,
    this.totalPaidIn = 0.0,
    this.totalPaidOut = 0.0,
    this.hasCashMovement = false,
    this.sessionId,
    this.registerId,
    this.registerName,
    this.isLoading = false,
    this.error,
    this.registers = const [],
  });

  final SessionStatus sessionStatus;
  final DateTime? startTime;
  final DateTime? endTime;
  final double openFloatUsd;
  final double openFloatKhr;
  final double totalPaidIn;
  final double totalPaidOut;
  final bool hasCashMovement;
  final String? sessionId;
  final String? registerId;
  final String? registerName;
  final bool isLoading;
  final String? error;
  final List<CashRegister> registers;

  /// Creates a copy of the state with the given fields replaced with the new values.
  CashSessionState copyWith({
    SessionStatus? sessionStatus,
    Object? startTime = _unset,
    Object? endTime = _unset,
    double? openFloatUsd,
    double? openFloatKhr,
    double? totalPaidIn,
    double? totalPaidOut,
    bool? hasCashMovement,
    Object? sessionId = _unset,
    Object? registerId = _unset,
    Object? registerName = _unset,
    bool? isLoading,
    String? error,
    List<CashRegister>? registers,
  }) {
    return CashSessionState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      startTime: startTime == _unset ? this.startTime : startTime as DateTime?,
      endTime: endTime == _unset ? this.endTime : endTime as DateTime?,
      openFloatUsd: openFloatUsd ?? this.openFloatUsd,
      openFloatKhr: openFloatKhr ?? this.openFloatKhr,
      totalPaidIn: totalPaidIn ?? this.totalPaidIn,
      totalPaidOut: totalPaidOut ?? this.totalPaidOut,
      hasCashMovement: hasCashMovement ?? this.hasCashMovement,
      sessionId: sessionId == _unset ? this.sessionId : sessionId as String?,
      registerId: registerId == _unset
          ? this.registerId
          : registerId as String?,
      registerName: registerName == _unset
          ? this.registerName
          : registerName as String?,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      registers: registers ?? this.registers,
    );
  }
}

/// The ViewModel that holds the business logic for managing the cash session state.
class CashSessionViewModel extends Notifier<CashSessionState> {
  CashSessionRepository get _repo => ref.read(cashSessionRepositoryProvider);

  @override
  CashSessionState build() {
    // Rebuild when auth or branch changes so session is tied to user context.
    ref.watch(
      loginControllerProvider.select(
        (state) => state.session?.accessToken ?? '',
      ),
    );
    ref.watch(authActiveBranchIdProvider);
    return const CashSessionState(isLoading: false);
  }

  Future<void> load({String? registerId, String? branchIdOverride}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final branchId = branchIdOverride ?? _currentBranchId();
      // Device-agnostic: skip register fetch; rely on branch-level session.
      state = state.copyWith(
        registers: const [],
        registerId: null,
        registerName: 'Branch Session',
      );
      await _fetchActiveSession(branchId: branchId, registerId: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        sessionStatus: SessionStatus.notStarted,
        sessionId: null,
        startTime: null,
        endTime: null,
        openFloatUsd: 0,
        openFloatKhr: 0,
        totalPaidIn: 0,
        totalPaidOut: 0,
        hasCashMovement: false,
      );
    }
  }

  void reset() {
    state = const CashSessionState(isLoading: false);
  }

  Future<void> _fetchActiveSession({
    String? branchId,
    String? registerId,
  }) async {
    try {
      final active = await _repo.getActiveSession(
        registerId: registerId,
        branchId: branchId,
      );
      if (active == null || active.id.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          sessionStatus: SessionStatus.notStarted,
          sessionId: null,
          startTime: null,
          endTime: null,
          openFloatUsd: 0,
          openFloatKhr: 0,
          totalPaidIn: 0,
          totalPaidOut: 0,
          hasCashMovement: false,
        );
        return;
      }
      _applySession(active);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        sessionStatus: SessionStatus.notStarted,
        sessionId: null,
        startTime: null,
        endTime: null,
        openFloatUsd: 0,
        openFloatKhr: 0,
        totalPaidIn: 0,
        totalPaidOut: 0,
        hasCashMovement: false,
      );
    }
  }

  Future<void> startSession({
    required double usdAmount,
    required double khrAmount,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final branchId = _currentBranchId();
      final session = await _repo.openSession(
        registerId: state.registerId,
        branchId: branchId,
        openingFloatUsd: usdAmount,
        openingFloatKhr: khrAmount,
        note: note,
      );
      _applySession(session);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addCashMovement(
    String type,
    double usdAmount,
    double khrAmount, {
    String? reason,
  }) async {
    if (state.sessionId == null || state.sessionId!.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
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
      await _repo.recordMovement(
        sessionId: state.sessionId!,
        type: normalizedType,
        amountUsd: usdAmount,
        amountKhr: khrAmount,
        reason: safeReason,
      );
      await _fetchActiveSession(
        branchId: _currentBranchId(),
        registerId: state.registerId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> closeSession({
    required double countedUsd,
    required double countedKhr,
    String? note,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await _repo.closeSession(
        sessionId: sessionId,
        countedCashUsd: countedUsd,
        countedCashKhr: countedKhr,
        note: note,
      );
      _applySession(session);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _applySession(CashSession session) {
    final sessionId = session.id;
    if (sessionId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        sessionStatus: SessionStatus.notStarted,
        sessionId: null,
        startTime: null,
        endTime: null,
        openFloatUsd: 0,
        openFloatKhr: 0,
        totalPaidIn: 0,
        totalPaidOut: 0,
        hasCashMovement: false,
      );
      return;
    }

    final ownerId = session.ownerId;
    final currentUserId = _currentUserId();
    if (ownerId != null &&
        ownerId.isNotEmpty &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        ownerId != currentUserId) {
      state = state.copyWith(
        isLoading: false,
        sessionStatus: SessionStatus.notStarted,
        sessionId: null,
        startTime: null,
        endTime: null,
        openFloatUsd: 0,
        openFloatKhr: 0,
        totalPaidIn: 0,
        totalPaidOut: 0,
        hasCashMovement: false,
      );
      return;
    }

    final statusRaw =
        session.status.trim().toLowerCase().isEmpty
            ? (session.closedAt != null ? 'closed' : 'open')
            : session.status.trim().toLowerCase();
    final status = switch (statusRaw) {
      'open' => SessionStatus.open,
      'closed' => SessionStatus.closed,
      _ => SessionStatus.notStarted,
    };

    final paidIn = session.totalPaidInUsd;
    final paidOut = session.totalPaidOutUsd;

    state = state.copyWith(
      isLoading: false,
      sessionStatus: status,
      sessionId: sessionId,
      startTime: session.openedAt,
      endTime: session.closedAt,
      openFloatUsd: session.openingFloatUsd,
      openFloatKhr: session.openingFloatKhr,
      totalPaidIn: paidIn,
      totalPaidOut: paidOut,
      hasCashMovement: paidIn > 0 || paidOut > 0,
    );
  }

  String? _currentBranchId() {
    return ref.read(authActiveBranchIdProvider);
  }

  String? _currentUserId() {
    return ref.read(loginControllerProvider).user?.id;
  }

}

/// The global provider for accessing the CashSessionViewModel.
final cashSessionViewModelProvider =
    NotifierProvider<CashSessionViewModel, CashSessionState>(
      CashSessionViewModel.new,
    );
