import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sales_repository.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_movement_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_sale_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

class RemoteCashSessionRepository
    implements
        CashSessionRepository,
        CashSessionMovementRepository,
        CashSessionSalesRepository {
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
  Future<void> recordPaidIn({
    required String sessionId,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await _api.recordPaidIn(sessionId, {
      'amountUsd': amountUsd,
      'amountKhr': amountKhr,
      'reason': (reason ?? 'Manual movement').trim().isEmpty
          ? 'Manual movement'
          : (reason ?? 'Manual movement').trim(),
    });
  }

  @override
  Future<void> recordPaidOut({
    required String sessionId,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  }) async {
    await _api.recordPaidOut(sessionId, {
      'amountUsd': amountUsd,
      'amountKhr': amountKhr,
      'reason': (reason ?? 'Manual movement').trim().isEmpty
          ? 'Manual movement'
          : (reason ?? 'Manual movement').trim(),
    });
  }

  @override
  Future<void> recordAdjustment({
    required String sessionId,
    required double amountUsdDelta,
    required double amountKhrDelta,
    String? reason,
  }) async {
    await _api.recordAdjustment(sessionId, {
      'amountUsdDelta': amountUsdDelta,
      'amountKhrDelta': amountKhrDelta,
      'reason': (reason ?? 'Manual adjustment').trim().isEmpty
          ? 'Manual adjustment'
          : (reason ?? 'Manual adjustment').trim(),
    });
  }

  @override
  Future<List<CashMovement>> listMovements({
    required String sessionId,
    int limit = 100,
    int offset = 0,
  }) async {
    final list = await _api.listMovements(
      sessionId,
      limit: limit,
      offset: offset,
    );
    return list.map(_toMovementDomain).toList();
  }

  @override
  Future<List<CashSessionSale>> listSales({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    final list = await _api.listSales(sessionId, limit: limit, offset: offset);
    return list.map(_toSaleDomain).toList();
  }

  CashSession _toDomain(CashSessionDto dto) {
    return CashSession(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      openedByAccountId: dto.openedByAccountId,
      openedByName: dto.openedByName,
      openedAt: dto.openedAt?.toLocal(),
      status: dto.status,
      openingFloatUsd: dto.openingFloatUsd,
      openingFloatKhr: dto.openingFloatKhr,
      closedAt: dto.closedAt?.toLocal(),
      closedByAccountId: dto.closedByAccountId,
      closedByName: dto.closedByName,
      closeNote: dto.closeNote,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    );
  }

  CashMovement _toMovementDomain(CashMovementDto dto) {
    return CashMovement(
      id: dto.id,
      sessionId: dto.sessionId,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      movementType: dto.movementType,
      amountUsd: dto.amountUsd,
      amountKhr: dto.amountKhr,
      reason: dto.reason,
      sourceRefType: dto.sourceRefType,
      sourceRefId: dto.sourceRefId,
      recordedByAccountId: dto.recordedByAccountId,
      occurredAt: dto.occurredAt?.toLocal(),
    );
  }

  CashSessionSale _toSaleDomain(CashSessionSaleDto dto) {
    return dto.toDomain();
  }
}
