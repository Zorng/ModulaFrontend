import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
    dotenv.testLoad();
  });

  group('MenuApi write lane', () {
    test(
      'createMenuItem uploads image first and attaches idempotency metadata only to item write',
      () async {
        final dio = _MockDio();
        final api = MenuApi.real(dio);
        var uploadCalled = false;

        when(
          () => dio.post<dynamic>(
            '/v0/menu/images/upload',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {
          uploadCalled = true;
          return Response<dynamic>(
            data: {
              'success': true,
              'data': {'imageUrl': 'https://cdn.example.com/menu/latte.jpg'},
            },
            requestOptions: RequestOptions(path: '/v0/menu/images/upload'),
          );
        });

        when(
          () => dio.post<Map<String, dynamic>>(
            '/v0/menu/items',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async {
          expect(uploadCalled, isTrue);
          return Response<Map<String, dynamic>>(
            data: {'success': true, 'data': _menuItemJson()},
            requestOptions: RequestOptions(path: '/v0/menu/items'),
          );
        });

        await api.createMenuItem(
          {
            'name': 'Latte',
            'basePrice': 2.5,
            'categoryId': 'cat-1',
            'visibleBranchIds': ['branch-1'],
            'modifierGroupIds': ['group-1'],
          },
          imageBytes: const [1, 2, 3],
        );

        verify(
          () => dio.post<dynamic>(
            '/v0/menu/images/upload',
            data: any(named: 'data'),
          ),
        ).called(1);
        verifyNever(
          () => dio.post<dynamic>(
            '/v0/menu/images/upload',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );

        final captured = verify(
          () => dio.post<Map<String, dynamic>>(
            '/v0/menu/items',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final body = Map<String, dynamic>.from(captured[0] as Map);
        final options = captured[1] as Options;
        final request = _idempotencyRequest(options);

        expect(body['imageUrl'], 'https://cdn.example.com/menu/latte.jpg');
        expect(request.actionKey, 'menu.items.create');
        expect(request.payload, body);
      },
    );

    test('updateMenuItem includes idempotency metadata', () async {
      final dio = _MockDio();
      final api = MenuApi.real(dio);

      when(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/menu/items/item-1',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'success': true,
            'data': _menuItemJson(id: 'item-1'),
          },
          requestOptions: RequestOptions(path: '/v0/menu/items/item-1'),
        ),
      );

      await api.updateMenuItem({
        'id': 'item-1',
        'name': 'Iced Latte',
        'basePrice': 3.0,
        'categoryId': 'cat-1',
        'visibleBranchIds': ['branch-1', 'branch-2'],
      });

      final captured = verify(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/menu/items/item-1',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      final body = Map<String, dynamic>.from(captured[0] as Map);
      final options = captured[1] as Options;
      final request = _idempotencyRequest(options);
      final requestPayload = Map<String, dynamic>.from(request.payload as Map);

      expect(body.containsKey('id'), isFalse);
      expect(request.actionKey, 'menu.items.update');
      expect(requestPayload['menuItemId'], 'item-1');
      expect(requestPayload['name'], 'Iced Latte');
    });

    test('archive/restore/visibility include idempotency metadata', () async {
      final dio = _MockDio();
      final api = MenuApi.real(dio);

      when(
        () => dio.post<void>(
          '/v0/menu/items/item-1/archive',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/v0/menu/items/item-1/archive'),
        ),
      );
      when(
        () => dio.post<void>(
          '/v0/menu/items/item-1/restore',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/v0/menu/items/item-1/restore'),
        ),
      );
      when(
        () => dio.put<void>(
          '/v0/menu/items/item-1/visibility',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/menu/items/item-1/visibility',
          ),
        ),
      );

      await api.deleteMenuItem('item-1');
      await api.restoreMenuItem('item-1');
      await api.setItemVisibility(
        menuItemId: 'item-1',
        visibleBranchIds: const ['branch-1', 'branch-2'],
      );

      final archiveOptions =
          verify(
                () => dio.post<void>(
                  '/v0/menu/items/item-1/archive',
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;
      final restoreOptions =
          verify(
                () => dio.post<void>(
                  '/v0/menu/items/item-1/restore',
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;
      final visibilityOptions =
          verify(
                () => dio.put<void>(
                  '/v0/menu/items/item-1/visibility',
                  data: any(named: 'data'),
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;

      expect(
        _idempotencyRequest(archiveOptions).actionKey,
        'menu.items.archive',
      );
      expect(
        _idempotencyRequest(restoreOptions).actionKey,
        'menu.items.restore',
      );
      expect(
        _idempotencyRequest(visibilityOptions).actionKey,
        'menu.items.visibility.set',
      );
    });
  });
}

IdempotencyRequest _idempotencyRequest(Options options) {
  final extra = options.extra ?? const <String, dynamic>{};
  final request = extra[idempotencyRequestExtraKey];
  expect(request, isA<IdempotencyRequest>());
  return request! as IdempotencyRequest;
}

Map<String, dynamic> _menuItemJson({String id = 'item-1'}) {
  return <String, dynamic>{
    'id': id,
    'tenantId': 'tenant-1',
    'name': 'Latte',
    'categoryId': 'cat-1',
    'basePrice': 2.5,
    'status': 'ACTIVE',
    'visibleBranchIds': ['branch-1'],
    'modifierGroupIds': ['group-1'],
  };
}
