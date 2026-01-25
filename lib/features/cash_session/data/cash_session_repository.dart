import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_register_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_register.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

final cashSessionRepositoryProvider = Provider<CashSessionRepository>((ref) {
  final api = ref.watch(cashSessionApiProvider);
  return CashSessionRepository(api);
});

class CashSessionRepository {
  CashSessionRepository(this._api);

  final CashSessionApi _api;

  Future<CashSession> openSession({
    String? registerId,
    String? branchId,
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) async {
    final dto = await _api.openSession({
      if (registerId != null && registerId.isNotEmpty) 'registerId': registerId,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      'openingFloatUsd': openingFloatUsd,
      'openingFloatKhr': openingFloatKhr,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return _toDomain(dto);
  }

  Future<CashSession> forceCloseSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    required String reason,
    String? note,
  }) async {
    final dto = await _api.forceCloseSession(sessionId, {
      'countedCashUsd': countedCashUsd,
      'countedCashKhr': countedCashKhr,
      'reason': reason,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return _toDomain(dto);
  }

  Future<CashSession> closeSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    String? note,
  }) async {
    final dto = await _api.closeSession(sessionId, {
      'countedCashUsd': countedCashUsd,
      'countedCashKhr': countedCashKhr,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return _toDomain(dto);
  }

  Future<CashSession?> getActiveSession({
    String? registerId,
    String? branchId,
  }) async {
    final dto = await _api.getActiveSession(registerId: registerId, branchId: branchId);
    if (dto == null || dto.id.isEmpty) return null;
    return _toDomain(dto);
  }

  Future<void> recordMovement({
    required String sessionId,
    required String type,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await _api.recordMovement(sessionId, {
      'type': type,
      'amountUsd': amountUsd,
      'amountKhr': amountKhr,
      'reason': (reason ?? 'Manual movement').trim().isEmpty
          ? 'Manual movement'
          : (reason ?? 'Manual movement').trim(),
    });
  }

  Future<List<CashRegister>> fetchRegisters({
    bool includeInactive = false,
  }) async {
    final list = await _api.fetchRegisters(includeInactive: includeInactive);
    return list.map(_toRegisterDomain).toList();
  }

  Future<CashRegister> createRegister(String name) async {
    final dto = await _api.createRegister(name);
    return _toRegisterDomain(dto);
  }

  CashSession _toDomain(CashSessionDto dto) {
    final ownerId = dto.openedBy ?? dto.createdBy ?? dto.actorId;
    return CashSession(
      id: dto.id,
      status: dto.status,
      openedAt: dto.openedAt?.toLocal(),
      closedAt: dto.closedAt?.toLocal(),
      openingFloatUsd: dto.openingFloatUsd,
      openingFloatKhr: dto.openingFloatKhr,
      totalPaidInUsd: dto.totalPaidInUsd,
      totalPaidOutUsd: dto.totalPaidOutUsd,
      ownerId: ownerId,
    );
  }

  CashRegister _toRegisterDomain(CashRegisterDto dto) {
    return CashRegister(
      id: dto.id,
      name: dto.name.isEmpty ? 'Register' : dto.name,
      status: dto.status,
    );
  }
}
