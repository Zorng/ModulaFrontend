import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_movement_dto.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';

void main() {
  test('CashMovementDto parses contract fields', () {
    final dto = CashMovementDto.fromJson({
      'id': 'movement-1',
      'sessionId': 'session-1',
      'tenantId': 'tenant-1',
      'branchId': 'branch-1',
      'movementType': 'manual_out',
      'amountUsd': 0,
      'amountKhr': 12000,
      'reason': 'Small expense',
      'sourceRefType': 'MANUAL',
      'sourceRefId': null,
      'recordedByAccountId': 'user-1',
      'occurredAt': '2026-03-07T09:30:00.000Z',
    });

    expect(dto.id, 'movement-1');
    expect(dto.sessionId, 'session-1');
    expect(dto.movementType, CashMovementTypes.manualOut);
    expect(dto.amountUsd, 0);
    expect(dto.amountKhr, 12000);
    expect(dto.reason, 'Small expense');
    expect(dto.sourceRefType, 'MANUAL');
    expect(dto.recordedByAccountId, 'user-1');
    expect(dto.occurredAt, DateTime.parse('2026-03-07T09:30:00.000Z'));
  });
}
