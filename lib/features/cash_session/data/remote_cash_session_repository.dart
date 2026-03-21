import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_history_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_mapper.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sales_repository.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_history_entry_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

class RemoteCashSessionRepository
    implements
        CashSessionRepository,
        CashSessionHistoryRepository,
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
    return mapCashSessionDto(dto);
  }

  @override
  Future<CashSession?> getActiveSession() async {
    final dto = await _api.getActiveSession();
    if (dto == null || dto.id.isEmpty) return null;
    return mapCashSessionDto(dto);
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
    return mapCashSessionDto(dto);
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
    return mapCashSessionDto(dto);
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
    return list.map(mapCashMovementDto).toList();
  }

  @override
  Future<List<CashSessionSale>> listSales({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    final list = await _api.listSales(sessionId, limit: limit, offset: offset);
    return list.map(mapCashSessionSaleDto).toList();
  }

  @override
  Future<List<CashSessionHistoryEntry>> listClosedSessions({
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final list = await _api.listSessions(
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
    final filtered = list
        .where((entry) => CashSessionStatuses.isClosed(entry.status))
        .map(_toHistoryDomain)
        .toList(growable: false);
    filtered.sort((a, b) {
      final aTime =
          a.closedAt ?? a.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.closedAt ?? b.openedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return filtered;
  }

  CashSessionHistoryEntry _toHistoryDomain(CashSessionHistoryEntryDto dto) {
    return CashSessionHistoryEntry(
      id: dto.id,
      status: dto.status,
      openedByName: dto.openedByName,
      openedAt: dto.openedAt?.toLocal(),
      closedAt: dto.closedAt?.toLocal(),
    );
  }
}
