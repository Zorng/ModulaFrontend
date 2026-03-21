import 'package:modular_pos/features/cash_session/data/dto/cash_movement_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_sale_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

CashSession mapCashSessionDto(
  CashSessionDto dto, {
  String? tenantIdFallback,
  String? branchIdFallback,
}) {
  return CashSession(
    id: dto.id,
    tenantId: dto.tenantId.trim().isNotEmpty
        ? dto.tenantId.trim()
        : (tenantIdFallback ?? '').trim(),
    branchId: dto.branchId.trim().isNotEmpty
        ? dto.branchId.trim()
        : (branchIdFallback ?? '').trim(),
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

CashMovement mapCashMovementDto(CashMovementDto dto) {
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

CashSessionSale mapCashSessionSaleDto(CashSessionSaleDto dto) {
  return dto.toDomain();
}
