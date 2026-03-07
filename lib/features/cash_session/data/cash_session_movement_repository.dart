import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';

abstract class CashSessionMovementRepository {
  Future<void> recordPaidIn({
    required String sessionId,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  });

  Future<void> recordPaidOut({
    required String sessionId,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  });

  Future<void> recordAdjustment({
    required String sessionId,
    required double amountUsdDelta,
    required double amountKhrDelta,
    String? reason,
  });

  Future<List<CashMovement>> listMovements({
    required String sessionId,
    int limit,
    int offset,
  });
}
