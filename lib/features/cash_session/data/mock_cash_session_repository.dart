import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_history_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sales_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

/// Mock repository for testing cash session features without backend
class MockCashSessionRepository
    implements
        CashSessionRepository,
        CashSessionHistoryRepository,
        CashSessionMovementRepository,
        CashSessionSalesRepository {
  // In-memory state
  CashSession? _activeSession;
  final List<CashMovement> _movements = <CashMovement>[];

  bool get isSessionOpen => _activeSession?.status == CashSessionStatuses.open;

  @override
  Future<CashSession> openSession({
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create new session
    _activeSession = CashSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: 'mock-tenant-001',
      branchId: 'mock-branch-001',
      openedByAccountId: '',
      openedByName: '',
      openedAt: DateTime.now(),
      status: CashSessionStatuses.open,
      openingFloatUsd: openingFloatUsd,
      openingFloatKhr: openingFloatKhr,
      closedAt: null,
      closedByAccountId: null,
      closedByName: null,
      closeNote: note,
      totalPaidInUsd: 0.0,
      totalPaidOutUsd: 0.0,
    );

    _movements.clear();

    return _activeSession!;
  }

  @override
  Future<CashSession> forceCloseSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    required String reason,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_activeSession == null || _activeSession!.id != sessionId) {
      throw Exception('No active session found');
    }

    _activeSession = CashSession(
      id: _activeSession!.id,
      tenantId: _activeSession!.tenantId,
      branchId: _activeSession!.branchId,
      openedByAccountId: _activeSession!.openedByAccountId,
      openedByName: _activeSession!.openedByName,
      openedAt: _activeSession!.openedAt,
      status: CashSessionStatuses.forceClosed,
      openingFloatUsd: _activeSession!.openingFloatUsd,
      openingFloatKhr: _activeSession!.openingFloatKhr,
      closedAt: DateTime.now(),
      closedByAccountId: '',
      closedByName: null,
      closeNote: note ?? reason,
      totalPaidInUsd: _movementTotalUsd(CashMovementTypes.manualIn),
      totalPaidOutUsd: _movementTotalUsd(CashMovementTypes.manualOut),
    );

    return _activeSession!;
  }

  @override
  Future<CashSession> closeSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_activeSession == null || _activeSession!.id != sessionId) {
      throw Exception('No active session found');
    }

    _activeSession = CashSession(
      id: _activeSession!.id,
      tenantId: _activeSession!.tenantId,
      branchId: _activeSession!.branchId,
      openedByAccountId: _activeSession!.openedByAccountId,
      openedByName: _activeSession!.openedByName,
      openedAt: _activeSession!.openedAt,
      status: CashSessionStatuses.closed,
      openingFloatUsd: _activeSession!.openingFloatUsd,
      openingFloatKhr: _activeSession!.openingFloatKhr,
      closedAt: DateTime.now(),
      closedByAccountId: '',
      closedByName: null,
      closeNote: note,
      totalPaidInUsd: _movementTotalUsd(CashMovementTypes.manualIn),
      totalPaidOutUsd: _movementTotalUsd(CashMovementTypes.manualOut),
    );

    return _activeSession!;
  }

  @override
  Future<CashSession?> getActiveSession() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return active session if it exists and is open
    if (_activeSession != null &&
        _activeSession!.status == CashSessionStatuses.open) {
      // Update with current movement totals
      return CashSession(
        id: _activeSession!.id,
        tenantId: _activeSession!.tenantId,
        branchId: _activeSession!.branchId,
        openedByAccountId: _activeSession!.openedByAccountId,
        openedByName: _activeSession!.openedByName,
        openedAt: _activeSession!.openedAt,
        status: _activeSession!.status,
        openingFloatUsd: _activeSession!.openingFloatUsd,
        openingFloatKhr: _activeSession!.openingFloatKhr,
        closedAt: _activeSession!.closedAt,
        closedByAccountId: _activeSession!.closedByAccountId,
        closedByName: _activeSession!.closedByName,
        closeNote: _activeSession!.closeNote,
        totalPaidInUsd: _movementTotalUsd(CashMovementTypes.manualIn),
        totalPaidOutUsd: _movementTotalUsd(CashMovementTypes.manualOut),
      );
    }

    return null;
  }

  @override
  Future<void> recordPaidIn({
    required String sessionId,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await _recordMovement(
      sessionId: sessionId,
      movementType: CashMovementTypes.manualIn,
      amountUsd: amountUsd,
      amountKhr: amountKhr,
      reason: reason,
    );
  }

  @override
  Future<void> recordPaidOut({
    required String sessionId,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await _recordMovement(
      sessionId: sessionId,
      movementType: CashMovementTypes.manualOut,
      amountUsd: amountUsd,
      amountKhr: amountKhr,
      reason: reason,
    );
  }

  @override
  Future<void> recordAdjustment({
    required String sessionId,
    required double amountUsdDelta,
    required double amountKhrDelta,
    String? reason,
  }) async {
    await _recordMovement(
      sessionId: sessionId,
      movementType: CashMovementTypes.adjustment,
      amountUsd: amountUsdDelta,
      amountKhr: amountKhrDelta,
      reason: reason,
    );
  }

  @override
  Future<List<CashMovement>> listMovements({
    required String sessionId,
    int limit = 100,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_activeSession == null || _activeSession!.id != sessionId) {
      return const [];
    }
    final start = offset.clamp(0, _movements.length);
    final end = (start + limit).clamp(0, _movements.length);
    return List<CashMovement>.unmodifiable(_movements.sublist(start, end));
  }

  @override
  Future<List<CashSessionSale>> listSales({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [];
  }

  @override
  Future<List<CashSessionHistoryEntry>> listClosedSessions({
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final session = _activeSession;
    if (session == null || !CashSessionStatuses.isClosed(session.status)) {
      return const [];
    }
    final closedAt = session.closedAt;
    if (closedAt == null) {
      return const [];
    }
    if (from != null && closedAt.isBefore(from)) {
      return const [];
    }
    if (to != null && closedAt.isAfter(to)) {
      return const [];
    }
    return [
      CashSessionHistoryEntry(
        id: session.id,
        status: session.status,
        openedByName: session.openedByName,
        openedAt: session.openedAt,
        closedAt: session.closedAt,
      ),
    ];
  }

  Future<void> _recordMovement({
    required String sessionId,
    required String movementType,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (_activeSession == null || _activeSession!.id != sessionId) {
      throw Exception('No active session found');
    }

    _movements.insert(
      0,
      CashMovement(
        id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        tenantId: _activeSession!.tenantId,
        branchId: _activeSession!.branchId,
        movementType: movementType,
        amountUsd: amountUsd,
        amountKhr: amountKhr,
        reason: reason,
        sourceRefType: 'MANUAL',
        sourceRefId: null,
        recordedByAccountId: _activeSession!.openedByAccountId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  double _movementTotalUsd(String movementType) {
    return _movements
        .where((movement) => movement.movementType == movementType)
        .fold<double>(0, (sum, movement) => sum + movement.amountUsd);
  }

  /// Reset all mock data (useful for testing)
  void reset() {
    _activeSession = null;
    _movements.clear();
  }
}

/// Provider for the mock repository
final mockCashSessionRepositoryProvider = Provider<MockCashSessionRepository>((
  ref,
) {
  return MockCashSessionRepository();
});
