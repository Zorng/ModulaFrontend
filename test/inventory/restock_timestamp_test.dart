import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/domain/utils/restock_timestamp.dart';

void main() {
  test('date-only restock timestamp keeps the current time-of-day', () {
    final reference = DateTime(2026, 4, 1, 14, 37, 12, 45, 678);

    final resolved = resolveRestockOccurredAt(
      '2026-04-05',
      referenceTime: reference,
    );
    final utcIso = restockOccurredAtToUtcIso(
      '2026-04-05',
      referenceTime: reference,
    );

    expect(resolved.year, 2026);
    expect(resolved.month, 4);
    expect(resolved.day, 5);
    expect(resolved.hour, 14);
    expect(resolved.minute, 37);
    expect(resolved.second, 12);
    expect(resolved.millisecond, 45);
    expect(resolved.microsecond, 678);
    expect(utcIso, isNotNull);
    expect(utcIso!.contains('T'), isTrue);
    expect(utcIso.endsWith('Z'), isTrue);
    expect(utcIso.contains('T00:00:00'), isFalse);
  });

  test('full datetime restock timestamp is preserved as-is', () {
    final resolved = resolveRestockOccurredAt('2026-04-05T09:15:30');

    expect(resolved.year, 2026);
    expect(resolved.month, 4);
    expect(resolved.day, 5);
    expect(resolved.hour, 9);
    expect(resolved.minute, 15);
    expect(resolved.second, 30);
  });
}
