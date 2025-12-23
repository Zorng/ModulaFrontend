import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';

final cashSessionRepositoryProvider = Provider<CashSessionRepository>((ref) {
  final api = ref.watch(cashSessionApiProvider);
  return CashSessionRepository(api);
});

class CashSessionRepository {
  CashSessionRepository(this._api);

  final CashSessionApi _api;

  Future<Map<String, dynamic>> openSession({
    String? registerId,
    String? branchId,
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) {
    return _api.openSession({
      if (registerId != null && registerId.isNotEmpty) 'registerId': registerId,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      'openingFloatUsd': openingFloatUsd,
      'openingFloatKhr': openingFloatKhr,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Map<String, dynamic>> forceCloseSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    required String reason,
    String? note,
  }) {
    return _api.forceCloseSession(sessionId, {
      'countedCashUsd': countedCashUsd,
      'countedCashKhr': countedCashKhr,
      'reason': reason,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Map<String, dynamic>> closeSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    String? note,
  }) {
    return _api.closeSession(sessionId, {
      'countedCashUsd': countedCashUsd,
      'countedCashKhr': countedCashKhr,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Map<String, dynamic>> getActiveSession({
    String? registerId,
    String? branchId,
  }) {
    return _api.getActiveSession(registerId: registerId, branchId: branchId);
  }

  Future<Map<String, dynamic>> recordMovement({
    required String sessionId,
    required String type,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) {
    return _api.recordMovement(sessionId, {
      'type': type,
      'amountUsd': amountUsd,
      'amountKhr': amountKhr,
      'reason': (reason ?? 'Manual movement').trim().isEmpty
          ? 'Manual movement'
          : (reason ?? 'Manual movement').trim(),
    });
  }

  Future<Map<String, dynamic>> fetchZReport({
    required String sessionId,
  }) {
    return _api.fetchZReport(sessionId);
  }

  Future<Map<String, dynamic>> fetchXReport({
    String? registerId,
  }) {
    return _api.fetchXReport(registerId: registerId);
  }

  Future<List<Map<String, dynamic>>> fetchRegisters({
    bool includeInactive = false,
  }) async {
    final data = await _api.fetchRegisters(includeInactive: includeInactive);
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createRegister(String name) {
    return _api.createRegister(name);
  }
}
