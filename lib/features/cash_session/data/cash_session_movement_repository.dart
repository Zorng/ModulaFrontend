import 'package:modular_pos/features/cash_session/domain/models/cash_register.dart';

abstract class CashSessionMovementRepository {
  Future<void> recordMovement({
    required String sessionId,
    required String type,
    required double amountUsd,
    required double amountKhr,
    String? reason,
  });

  Future<List<CashRegister>> fetchRegisters({bool includeInactive = false});

  Future<CashRegister> createRegister(String name);
}
