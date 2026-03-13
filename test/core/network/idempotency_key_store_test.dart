import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';

void main() {
  group('InMemoryIdempotencyKeyStore', () {
    test('returns same key for same action+payload', () async {
      final store = InMemoryIdempotencyKeyStore();
      const request = IdempotencyRequest(
        actionKey: 'sale.finalize',
        payload: {'saleId': 's1', 'amount': 10},
      );

      final first = await store.getOrCreateKey(request);
      final second = await store.getOrCreateKey(request);

      expect(second, first);
    });

    test(
      'returns different key for same action with different payload',
      () async {
        final store = InMemoryIdempotencyKeyStore();
        const requestA = IdempotencyRequest(
          actionKey: 'sale.finalize',
          payload: {'saleId': 's1', 'amount': 10},
        );
        const requestB = IdempotencyRequest(
          actionKey: 'sale.finalize',
          payload: {'saleId': 's1', 'amount': 12},
        );

        final first = await store.getOrCreateKey(requestA);
        final second = await store.getOrCreateKey(requestB);

        expect(second, isNot(first));
      },
    );

    test('uses intentId in fingerprint when provided', () async {
      final store = InMemoryIdempotencyKeyStore();
      const requestA = IdempotencyRequest(
        actionKey: 'sale.finalize',
        intentId: 'intent-a',
        payload: {'saleId': 's1'},
      );
      const requestB = IdempotencyRequest(
        actionKey: 'sale.finalize',
        intentId: 'intent-b',
        payload: {'saleId': 's1'},
      );

      final first = await store.getOrCreateKey(requestA);
      final second = await store.getOrCreateKey(requestB);

      expect(second, isNot(first));
    });
  });

  test(
    'withIdempotency keeps existing options and appends request metadata',
    () {
      final options = withIdempotency(
        options: Options(headers: {'X-Test': '1'}, extra: {'foo': 'bar'}),
        request: const IdempotencyRequest(
          actionKey: 'menu.items.create',
          payload: {'name': 'Latte'},
        ),
      );

      expect(options.headers?['X-Test'], '1');
      final extra = options.extra ?? const <String, dynamic>{};
      expect(extra['foo'], 'bar');
      expect(extra[idempotencyRequestExtraKey], isA<IdempotencyRequest>());
    },
  );
}
