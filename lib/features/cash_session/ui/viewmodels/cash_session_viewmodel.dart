import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';

/// Enum to represent the distinct states of a cash session.
enum SessionStatus { notStarted, open, closed }

class CashRegister {
  CashRegister({required this.id, required this.name, this.status = 'ACTIVE'});
  final String id;
  final String name;
  final String status;

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Register',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

/// An immutable class that holds the state for a cash session.
class CashSessionState {
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
    DateTime? startTime,
    DateTime? endTime,
    double? openFloatUsd,
    double? openFloatKhr,
    double? totalPaidIn,
    double? totalPaidOut,
    bool? hasCashMovement,
    String? sessionId,
    String? registerId,
    String? registerName,
    bool? isLoading,
    String? error,
    List<CashRegister>? registers,
  }) {
    return CashSessionState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      openFloatUsd: openFloatUsd ?? this.openFloatUsd,
      openFloatKhr: openFloatKhr ?? this.openFloatKhr,
      totalPaidIn: totalPaidIn ?? this.totalPaidIn,
      totalPaidOut: totalPaidOut ?? this.totalPaidOut,
      hasCashMovement: hasCashMovement ?? this.hasCashMovement,
      sessionId: sessionId ?? this.sessionId,
      registerId: registerId ?? this.registerId,
      registerName: registerName ?? this.registerName,
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
    Future.microtask(load);
    return const CashSessionState(isLoading: true);
  }

  Future<void> load({String? registerId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final branchId = _currentBranchId();
      // Device-agnostic: skip register fetch; rely on branch-level session.
      state = state.copyWith(
        registers: const [],
        registerId: null,
        registerName: 'Branch Session',
      );
      await _fetchActiveSession(branchId: branchId, registerId: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchActiveSession({
    String? branchId,
    String? registerId,
  }) async {
    try {
      final payload = await _repo.getActiveSession(
        registerId: registerId,
        branchId: branchId,
      );
      final data = _unwrapData(payload);
      if (data.isEmpty) {
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
      _applySessionPayload(data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      final payload = await _repo.openSession(
        registerId: state.registerId,
        branchId: branchId,
        openingFloatUsd: usdAmount,
        openingFloatKhr: khrAmount,
        note: note,
      );
      _applySessionPayload(_unwrapData(payload));
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
      final payload = await _repo.closeSession(
        sessionId: sessionId,
        countedCashUsd: countedUsd,
        countedCashKhr: countedKhr,
        note: note,
      );
      _applySessionPayload(_unwrapData(payload));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> payload) {
    if (payload['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payload['data'] as Map);
    }
    return payload;
  }

  void _applySessionPayload(Map<String, dynamic> json) {
    final sessionId =
        json['id']?.toString() ?? json['sessionId']?.toString() ?? '';
    final start = DateTime.tryParse(
      json['startedAt']?.toString() ?? json['createdAt']?.toString() ?? '',
    );
    final end = DateTime.tryParse(json['closedAt']?.toString() ?? '');
    final openingUsd = (json['openingFloatUsd'] as num?)?.toDouble() ?? 0;
    final openingKhr = (json['openingFloatKhr'] as num?)?.toDouble() ?? 0;
    final paidIn =
        (json['totalPaidInUsd'] as num?)?.toDouble() ??
        (json['totalPaidIn'] as num?)?.toDouble() ??
        0;
    final paidOut =
        (json['totalPaidOutUsd'] as num?)?.toDouble() ??
        (json['totalPaidOut'] as num?)?.toDouble() ??
        0;
    final statusRaw =
        json['status']?.toString().toLowerCase() ??
        (end != null ? 'closed' : 'open');
    final status = switch (statusRaw) {
      'open' => SessionStatus.open,
      'closed' => SessionStatus.closed,
      _ => SessionStatus.notStarted,
    };
    state = state.copyWith(
      isLoading: false,
      sessionStatus: status,
      sessionId: sessionId.isNotEmpty ? sessionId : state.sessionId,
      startTime: start ?? state.startTime,
      endTime: end,
      openFloatUsd: openingUsd,
      openFloatKhr: openingKhr,
      totalPaidIn: paidIn,
      totalPaidOut: paidOut,
      hasCashMovement: paidIn > 0 || paidOut > 0,
      registerId: state.registerId,
      registerName: state.registerName,
    );
  }

  String? _currentBranchId() {
    final session = ref.read(loginControllerProvider).session;
    final branches = session?.user.branches ?? const [];
    if (branches.isEmpty) return null;
    final active = branches.firstWhere(
      (b) => b.active && b.branchId.isNotEmpty,
      orElse: () => branches.first,
    );
    return active.branchId.isNotEmpty ? active.branchId : active.id;
  }
}

/// The global provider for accessing the CashSessionViewModel.
final cashSessionViewModelProvider =
    NotifierProvider<CashSessionViewModel, CashSessionState>(
      CashSessionViewModel.new,
    );
