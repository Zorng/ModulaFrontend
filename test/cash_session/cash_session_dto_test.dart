import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_envelope_dto.dart';

void main() {
  test('CashSessionDto parses current contract fields', () {
    final dto = CashSessionDto.fromJson({
      'id': 'session-1',
      'tenantId': 'tenant-1',
      'branchId': 'branch-1',
      'openedByAccountId': 'account-1',
      'openedAt': '2026-02-19T01:00:00.000Z',
      'status': 'OPEN',
      'openingFloatUsd': 20,
      'openingFloatKhr': 50000,
      'closedAt': null,
      'closedByAccountId': null,
      'closeNote': null,
    });

    expect(dto.id, 'session-1');
    expect(dto.tenantId, 'tenant-1');
    expect(dto.branchId, 'branch-1');
    expect(dto.openedByAccountId, 'account-1');
    expect(dto.status, CashSessionStatuses.open);
    expect(dto.openingFloatUsd, 20);
    expect(dto.openingFloatKhr, 50000);
    expect(dto.closedByAccountId, isNull);
    expect(dto.closeNote, isNull);
  });

  test('CashSessionDto parses closed-session payload fields', () {
    final dto = CashSessionDto.fromJson({
      'id': 'session-2',
      'tenantId': 'tenant-1',
      'branchId': 'branch-1',
      'openedByAccountId': 'account-1',
      'openedAt': '2026-02-19T01:00:00.000Z',
      'status': 'CLOSED',
      'openingFloatUsd': 30,
      'openingFloatKhr': 120000,
      'closedAt': '2026-02-19T09:00:00.000Z',
      'closedByAccountId': 'account-2',
      'closeNote': 'End of shift',
    });

    expect(dto.id, 'session-2');
    expect(dto.status, CashSessionStatuses.closed);
    expect(dto.closedAt, isNotNull);
    expect(dto.closedByAccountId, 'account-2');
    expect(dto.closeNote, 'End of shift');
  });

  test('CashSessionEnvelopeDto parses nullable session payload', () {
    final envelope = CashSessionEnvelopeDto.fromJson({
      'session': {
        'id': 'session-1',
        'tenantId': 'tenant-1',
        'branchId': 'branch-1',
        'openedByAccountId': 'account-1',
        'openedAt': '2026-02-19T01:00:00.000Z',
        'status': 'OPEN',
        'openingFloatUsd': 20,
        'openingFloatKhr': 50000,
        'closedAt': null,
        'closedByAccountId': null,
        'closeNote': null,
      },
    });

    expect(envelope.session, isNotNull);
    expect(envelope.session!.id, 'session-1');
  });

  test('CashSessionEnvelopeDto returns null when session is absent', () {
    final envelope = CashSessionEnvelopeDto.fromJson({'session': null});
    expect(envelope.session, isNull);
  });

  test('CashSessionDto normalizes FORCE_CLOSED status values', () {
    final dto = CashSessionDto.fromJson({
      'id': 'session-1',
      'tenantId': 'tenant-1',
      'branchId': 'branch-1',
      'openedByAccountId': 'account-1',
      'openedAt': '2026-02-19T01:00:00.000Z',
      'status': ' force_closed ',
      'openingFloatUsd': 20,
      'openingFloatKhr': 50000,
      'closedAt': '2026-02-19T09:00:00.000Z',
      'closedByAccountId': 'account-2',
      'closeNote': 'Manager override',
    });

    expect(dto.status, CashSessionStatuses.forceClosed);
  });
}
