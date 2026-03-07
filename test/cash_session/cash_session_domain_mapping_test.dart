import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

void main() {
  test('CashSession domain model carries the contract start/end fields', () {
    final session = CashSession(
      id: 'session-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      openedByAccountId: 'account-1',
      openedAt: null,
      status: 'OPEN',
      openingFloatUsd: 20,
      openingFloatKhr: 50000,
      closedAt: null,
      closedByAccountId: null,
      closeNote: null,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    );

    expect(session.tenantId, 'tenant-1');
    expect(session.branchId, 'branch-1');
    expect(session.openedByAccountId, 'account-1');
    expect(session.closedByAccountId, isNull);
    expect(session.closeNote, isNull);
  });

  test('CashSession normalizes contract status values', () {
    final session = CashSession(
      id: 'session-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      openedByAccountId: 'account-1',
      openedAt: null,
      status: ' force_closed ',
      openingFloatUsd: 20,
      openingFloatKhr: 50000,
      closedAt: null,
      closedByAccountId: null,
      closeNote: null,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    );

    expect(session.status, CashSessionStatuses.forceClosed);
    expect(CashSessionStatuses.isClosed(session.status), isTrue);
  });
}
