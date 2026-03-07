import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_register.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

/// Mock repository for testing cash session features without backend
class MockCashSessionRepository
    implements CashSessionRepository, CashSessionMovementRepository {
  // In-memory state
  CashSession? _activeSession;
  final List<CashRegister> _registers = [
    CashRegister(id: 'reg-1', name: 'Main Register', status: 'active'),
    CashRegister(id: 'reg-2', name: 'Secondary Register', status: 'active'),
  ];

  // Track movements for the active session
  double _totalPaidInUsd = 0.0;
  double _totalPaidOutUsd = 0.0;

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
      openedAt: DateTime.now(),
      status: CashSessionStatuses.open,
      openingFloatUsd: openingFloatUsd,
      openingFloatKhr: openingFloatKhr,
      closedAt: null,
      closedByAccountId: null,
      closeNote: note,
      totalPaidInUsd: 0.0,
      totalPaidOutUsd: 0.0,
    );

    // Reset movement totals
    _totalPaidInUsd = 0.0;
    _totalPaidOutUsd = 0.0;

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
      openedAt: _activeSession!.openedAt,
      status: CashSessionStatuses.forceClosed,
      openingFloatUsd: _activeSession!.openingFloatUsd,
      openingFloatKhr: _activeSession!.openingFloatKhr,
      closedAt: DateTime.now(),
      closedByAccountId: '',
      closeNote: note ?? reason,
      totalPaidInUsd: _totalPaidInUsd,
      totalPaidOutUsd: _totalPaidOutUsd,
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
      openedAt: _activeSession!.openedAt,
      status: CashSessionStatuses.closed,
      openingFloatUsd: _activeSession!.openingFloatUsd,
      openingFloatKhr: _activeSession!.openingFloatKhr,
      closedAt: DateTime.now(),
      closedByAccountId: '',
      closeNote: note,
      totalPaidInUsd: _totalPaidInUsd,
      totalPaidOutUsd: _totalPaidOutUsd,
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
        openedAt: _activeSession!.openedAt,
        status: _activeSession!.status,
        openingFloatUsd: _activeSession!.openingFloatUsd,
        openingFloatKhr: _activeSession!.openingFloatKhr,
        closedAt: _activeSession!.closedAt,
        closedByAccountId: _activeSession!.closedByAccountId,
        closeNote: _activeSession!.closeNote,
        totalPaidInUsd: _totalPaidInUsd,
        totalPaidOutUsd: _totalPaidOutUsd,
      );
    }

    return null;
  }

  @override
  Future<void> recordMovement({
    required String sessionId,
    required String type,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (_activeSession == null || _activeSession!.id != sessionId) {
      throw Exception('No active session found');
    }

    // Update movement totals based on type
    if (type.toUpperCase() == 'PAID_IN') {
      _totalPaidInUsd += amountUsd;
    } else if (type.toUpperCase() == 'PAID_OUT') {
      _totalPaidOutUsd += amountUsd;
    }
  }

  @override
  Future<List<CashRegister>> fetchRegisters({
    bool includeInactive = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (includeInactive) {
      return _registers;
    }

    return _registers.where((r) => r.status == 'active').toList();
  }

  @override
  Future<CashRegister> createRegister(String name) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final newRegister = CashRegister(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      status: 'active',
    );

    _registers.add(newRegister);
    return newRegister;
  }

  /// Reset all mock data (useful for testing)
  void reset() {
    _activeSession = null;
    _totalPaidInUsd = 0.0;
    _totalPaidOutUsd = 0.0;
  }
}

/// Provider for the mock repository
final mockCashSessionRepositoryProvider = Provider<MockCashSessionRepository>((
  ref,
) {
  return MockCashSessionRepository();
});
