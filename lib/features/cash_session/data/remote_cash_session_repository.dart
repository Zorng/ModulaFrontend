import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_register_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_register.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

class RemoteCashSessionRepository
    implements CashSessionRepository, CashSessionMovementRepository {
  RemoteCashSessionRepository(this._api);

  final CashSessionApi _api;

  @override
  Future<CashSession> openSession({
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) async {
    final dto = await _api.openSession({
      'openingFloatUsd': openingFloatUsd,
      'openingFloatKhr': openingFloatKhr,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return _toDomain(dto);
  }

  @override
  Future<CashSession?> getActiveSession() async {
    final dto = await _api.getActiveSession();
    if (dto == null || dto.id.isEmpty) return null;
    return _toDomain(dto);
  }

  @override
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

  @override
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

  @override
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

  @override
  Future<List<CashRegister>> fetchRegisters({
    bool includeInactive = false,
  }) async {
    final list = await _api.fetchRegisters(includeInactive: includeInactive);
    return list.map(_toRegisterDomain).toList();
  }

  @override
  Future<CashRegister> createRegister(String name) async {
    final dto = await _api.createRegister(name);
    return _toRegisterDomain(dto);
  }

  CashSession _toDomain(CashSessionDto dto) {
    return CashSession(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      openedByAccountId: dto.openedByAccountId,
      openedAt: dto.openedAt?.toLocal(),
      status: dto.status,
      openingFloatUsd: dto.openingFloatUsd,
      openingFloatKhr: dto.openingFloatKhr,
      closedAt: dto.closedAt?.toLocal(),
      closedByAccountId: dto.closedByAccountId,
      closeNote: dto.closeNote,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
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
