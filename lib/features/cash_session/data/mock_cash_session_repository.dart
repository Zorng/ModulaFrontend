import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_register.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

/// Mock repository for testing cash session features without backend
class MockCashSessionRepository {
  // In-memory state
  CashSession? _activeSession;
  final List<CashRegister> _registers = [
    CashRegister(id: 'reg-1', name: 'Main Register', status: 'active'),
    CashRegister(id: 'reg-2', name: 'Secondary Register', status: 'active'),
  ];

  // Track movements for the active session
  double _totalPaidInUsd = 0.0;
  double _totalPaidOutUsd = 0.0;

  bool get isSessionOpen => _activeSession?.status.toLowerCase() == 'open';

  Future<CashSession> openSession({
    String? registerId,
    String? branchId,
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create new session
    _activeSession = CashSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      status: 'open',
      openedAt: DateTime.now(),
      closedAt: null,
      openingFloatUsd: openingFloatUsd,
      openingFloatKhr: openingFloatKhr,
      totalPaidInUsd: 0.0,
      totalPaidOutUsd: 0.0,
      ownerId: null, // Use null to bypass owner check in viewmodel
    );

    // Reset movement totals
    _totalPaidInUsd = 0.0;
    _totalPaidOutUsd = 0.0;

    return _activeSession!;
  }

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
      status: 'closed',
      openedAt: _activeSession!.openedAt,
      closedAt: DateTime.now(),
      openingFloatUsd: _activeSession!.openingFloatUsd,
      openingFloatKhr: _activeSession!.openingFloatKhr,
      totalPaidInUsd: _totalPaidInUsd,
      totalPaidOutUsd: _totalPaidOutUsd,
      ownerId: _activeSession!.ownerId,
    );

    return _activeSession!;
  }

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
      status: 'closed',
      openedAt: _activeSession!.openedAt,
      closedAt: DateTime.now(),
      openingFloatUsd: _activeSession!.openingFloatUsd,
      openingFloatKhr: _activeSession!.openingFloatKhr,
      totalPaidInUsd: _totalPaidInUsd,
      totalPaidOutUsd: _totalPaidOutUsd,
      ownerId: _activeSession!.ownerId,
    );

    return _activeSession!;
  }

  Future<CashSession?> getActiveSession({
    String? registerId,
    String? branchId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return active session if it exists and is open
    if (_activeSession != null && _activeSession!.status == 'open') {
      // Update with current movement totals
      return CashSession(
        id: _activeSession!.id,
        status: _activeSession!.status,
        openedAt: _activeSession!.openedAt,
        closedAt: _activeSession!.closedAt,
        openingFloatUsd: _activeSession!.openingFloatUsd,
        openingFloatKhr: _activeSession!.openingFloatKhr,
        totalPaidInUsd: _totalPaidInUsd,
        totalPaidOutUsd: _totalPaidOutUsd,
        ownerId: _activeSession!.ownerId,
      );
    }

    return null;
  }

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

  Future<List<CashRegister>> fetchRegisters({
    bool includeInactive = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (includeInactive) {
      return _registers;
    }

    return _registers.where((r) => r.status == 'active').toList();
  }

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
