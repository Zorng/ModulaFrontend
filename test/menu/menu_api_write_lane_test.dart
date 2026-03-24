import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_modifier_option_effect_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';

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

    test('category writes include idempotency metadata', () async {
      final dio = _MockDio();
      final api = MenuApi.real(dio);

      when(
        () => dio.post<Map<String, dynamic>>(
          '/v0/menu/categories',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'success': true,
            'data': {'id': 'cat-1', 'tenantId': 'tenant-1', 'name': 'Coffee'},
          },
          requestOptions: RequestOptions(path: '/v0/menu/categories'),
        ),
      );
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/menu/categories/cat-1',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'success': true,
            'data': {'id': 'cat-1', 'tenantId': 'tenant-1', 'name': 'Coffee'},
          },
          requestOptions: RequestOptions(path: '/v0/menu/categories/cat-1'),
        ),
      );
      when(
        () => dio.post<void>(
          '/v0/menu/categories/cat-1/archive',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/menu/categories/cat-1/archive',
          ),
        ),
      );
      when(
        () => dio.post<void>(
          '/v0/menu/categories/cat-1/restore',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(
            path: '/v0/menu/categories/cat-1/restore',
          ),
        ),
      );

      await api.createCategory({'name': 'Coffee'});
      await api.updateCategory({'id': 'cat-1', 'name': 'Coffee & Tea'});
      await api.deleteCategory('cat-1');
      await api.restoreCategory('cat-1');

      final createOptions =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  '/v0/menu/categories',
                  data: any(named: 'data'),
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;
      final updateCaptured = verify(
        () => dio.patch<Map<String, dynamic>>(
          '/v0/menu/categories/cat-1',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      final updateBody = Map<String, dynamic>.from(updateCaptured[0] as Map);
      final updateOptions = updateCaptured[1] as Options;
      final archiveOptions =
          verify(
                () => dio.post<void>(
                  '/v0/menu/categories/cat-1/archive',
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;
      final restoreOptions =
          verify(
                () => dio.post<void>(
                  '/v0/menu/categories/cat-1/restore',
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as Options;

      expect(
        _idempotencyRequest(createOptions).actionKey,
        'menu.categories.create',
      );
      expect(
        _idempotencyRequest(updateOptions).actionKey,
        'menu.categories.update',
      );
      expect(_idempotencyRequest(updateOptions).payload, {
        'categoryId': 'cat-1',
        ...updateBody,
      });
      expect(
        _idempotencyRequest(archiveOptions).actionKey,
        'menu.categories.archive',
      );
      expect(
        _idempotencyRequest(restoreOptions).actionKey,
        'menu.categories.restore',
      );
    });

    test(
      'modifier writes normalize payload and include idempotency metadata',
      () async {
        final dio = _MockDio();
        final api = MenuApi.real(dio);

        when(
          () => dio.post<Map<String, dynamic>>(
            '/v0/menu/modifier-groups',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'success': true,
              'data': _modifierGroupJson(id: 'group-1', name: 'Size'),
            },
            requestOptions: RequestOptions(path: '/v0/menu/modifier-groups'),
          ),
        );
        when(
          () => dio.patch<Map<String, dynamic>>(
            '/v0/menu/modifier-groups/group-1',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'success': true,
              'data': _modifierGroupJson(id: 'group-1', name: 'Sizes'),
            },
            requestOptions: RequestOptions(
              path: '/v0/menu/modifier-groups/group-1',
            ),
          ),
        );
        when(
          () => dio.post<void>(
            '/v0/menu/modifier-groups/group-1/archive',
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(
              path: '/v0/menu/modifier-groups/group-1/archive',
            ),
          ),
        );
        when(
          () => dio.post<Map<String, dynamic>>(
            '/v0/menu/modifier-groups/group-1/options',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'success': true,
              'data': _modifierOptionJson(id: 'opt-1', groupId: 'group-1'),
            },
            requestOptions: RequestOptions(
              path: '/v0/menu/modifier-groups/group-1/options',
            ),
          ),
        );
        when(
          () => dio.patch<Map<String, dynamic>>(
            '/v0/menu/modifier-groups/group-1/options/opt-1',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'success': true,
              'data': _modifierOptionJson(id: 'opt-1', groupId: 'group-1'),
            },
            requestOptions: RequestOptions(
              path: '/v0/menu/modifier-groups/group-1/options/opt-1',
            ),
          ),
        );
        when(
          () => dio.post<void>(
            '/v0/menu/modifier-groups/group-1/options/opt-1/archive',
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(
              path: '/v0/menu/modifier-groups/group-1/options/opt-1/archive',
            ),
          ),
        );
        when(
          () => dio.post<void>(
            '/v0/menu/modifier-groups/group-1/options/opt-1/restore',
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(
              path: '/v0/menu/modifier-groups/group-1/options/opt-1/restore',
            ),
          ),
        );

        await api.createModifierGroup({
          'name': 'Size',
          'selectionType': 'multiple',
          'minSelections': 1,
          'maxSelections': 2,
          'isRequired': true,
        });
        await api.updateModifierGroup({
          'id': 'group-1',
          'name': 'Sizes',
          'selectionMode': 'SINGLE',
          'minSelections': 0,
          'maxSelections': 1,
          'isRequired': false,
        });
        await api.addModifierOption({
          'groupId': 'group-1',
          'name': 'Large',
          'price': 0.5,
          'componentDeltas': [
            {
              'stockItemId': 'stock-1',
              'quantityDeltaInBaseUnit': 100,
              'trackingMode': 'TRACKED',
            },
          ],
        });
        await api.updateModifierOption('opt-1', {
          'groupId': 'group-1',
          'name': 'XL',
          'priceAdjustmentUsd': 1.0,
          'componentDeltas': [
            {
              'stockItemId': 'stock-1',
              'quantityDeltaInBaseUnit': 150,
              'trackingMode': 'TRACKED',
            },
          ],
        });
        await api.deleteModifierOption('opt-1', groupId: 'group-1');
        await api.restoreModifierOption('opt-1', groupId: 'group-1');
        await api.deleteModifierGroup('group-1');

        final createGroupCaptured = verify(
          () => dio.post<Map<String, dynamic>>(
            '/v0/menu/modifier-groups',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final createGroupBody = Map<String, dynamic>.from(
          createGroupCaptured[0] as Map,
        );
        final createGroupOptions = createGroupCaptured[1] as Options;

        final updateGroupCaptured = verify(
          () => dio.patch<Map<String, dynamic>>(
            '/v0/menu/modifier-groups/group-1',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final updateGroupBody = Map<String, dynamic>.from(
          updateGroupCaptured[0] as Map,
        );
        final updateGroupOptions = updateGroupCaptured[1] as Options;

        final createOptionCaptured = verify(
          () => dio.post<Map<String, dynamic>>(
            '/v0/menu/modifier-groups/group-1/options',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final createOptionBody = Map<String, dynamic>.from(
          createOptionCaptured[0] as Map,
        );
        final createOptionOptions = createOptionCaptured[1] as Options;

        final updateOptionCaptured = verify(
          () => dio.patch<Map<String, dynamic>>(
            '/v0/menu/modifier-groups/group-1/options/opt-1',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final updateOptionBody = Map<String, dynamic>.from(
          updateOptionCaptured[0] as Map,
        );
        final updateOptionOptions = updateOptionCaptured[1] as Options;

        final archiveOptionOptions =
            verify(
                  () => dio.post<void>(
                    '/v0/menu/modifier-groups/group-1/options/opt-1/archive',
                    options: captureAny(named: 'options'),
                  ),
                ).captured.single
                as Options;
        final restoreOptionOptions =
            verify(
                  () => dio.post<void>(
                    '/v0/menu/modifier-groups/group-1/options/opt-1/restore',
                    options: captureAny(named: 'options'),
                  ),
                ).captured.single
                as Options;
        final archiveGroupOptions =
            verify(
                  () => dio.post<void>(
                    '/v0/menu/modifier-groups/group-1/archive',
                    options: captureAny(named: 'options'),
                  ),
                ).captured.single
                as Options;

        expect(createGroupBody['selectionMode'], 'MULTI');
        expect(createGroupBody['minSelections'], 1);
        expect(createGroupBody['maxSelections'], 2);
        expect(
          _idempotencyRequest(createGroupOptions).actionKey,
          'menu.modifierGroups.create',
        );

        expect(updateGroupBody['selectionMode'], 'SINGLE');
        expect(
          _idempotencyRequest(updateGroupOptions).actionKey,
          'menu.modifierGroups.update',
        );

        expect(createOptionBody['label'], 'Large');
        expect(createOptionBody['priceDelta'], 0.5);
        expect(createOptionBody['componentDeltas'], [
          {
            'stockItemId': 'stock-1',
            'quantityDeltaInBaseUnit': 100,
            'trackingMode': 'TRACKED',
          },
        ]);
        expect(
          _idempotencyRequest(createOptionOptions).actionKey,
          'menu.modifierOptions.create',
        );

        expect(updateOptionBody['label'], 'XL');
        expect(updateOptionBody['priceDelta'], 1.0);
        expect(
          _idempotencyRequest(updateOptionOptions).actionKey,
          'menu.modifierOptions.update',
        );

        expect(
          _idempotencyRequest(archiveOptionOptions).actionKey,
          'menu.modifierOptions.archive',
        );
        expect(
          _idempotencyRequest(restoreOptionOptions).actionKey,
          'menu.modifierOptions.restore',
        );
        expect(
          _idempotencyRequest(archiveGroupOptions).actionKey,
          'menu.modifierGroups.archive',
        );
      },
    );

    test(
      'explicit detail endpoint maps GET /v0/menu/items/:menuItemId',
      () async {
        final dio = _MockDio();
        final api = MenuApi.real(dio);

        when(
          () => dio.get<dynamic>('/v0/menu/items/item-1'),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            data: {
              'success': true,
              'data': {
                ..._menuItemJson(id: 'item-1'),
                'categoryName': 'Coffee',
                'baseComponents': [
                  {
                    'stockItemId': 'stock-1',
                    'quantityInBaseUnit': 250,
                    'trackingMode': 'TRACKED',
                  },
                ],
                'modifierOptionEffects': [
                  {
                    'modifierOptionId': 'opt-1',
                    'components': [
                      {
                        'stockItemId': 'stock-2',
                        'quantityDeltaInBaseUnit': 50,
                        'trackingMode': 'TRACKED',
                      },
                    ],
                  },
                ],
                'modifierGroups': [
                  _modifierGroupJson(id: 'group-1', name: 'Size'),
                ],
              },
            },
            requestOptions: RequestOptions(path: '/v0/menu/items/item-1'),
          ),
        );

        final detail = await api.fetchMenuItemDetail('item-1');

        verify(() => dio.get<dynamic>('/v0/menu/items/item-1')).called(1);
        expect(detail.item.id, 'item-1');
        expect(detail.categoryName, 'Coffee');
        expect(detail.baseComponents, hasLength(1));
        expect(detail.baseComponents.first.stockItemId, 'stock-1');
        expect(detail.modifierOptionEffects, hasLength(1));
        expect(detail.modifierOptionEffects.first.modifierOptionId, 'opt-1');
      },
    );

    test(
      'composition upsert uses idempotency and evaluate remains read-only call',
      () async {
        final dio = _MockDio();
        final api = MenuApi.real(dio);

        when(
          () => dio.put<void>(
            '/v0/menu/items/item-1/composition',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(
              path: '/v0/menu/items/item-1/composition',
            ),
          ),
        );
        when(
          () => dio.post<dynamic>(
            '/v0/menu/items/item-1/composition/evaluate',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            data: {
              'success': true,
              'data': {
                'menuItemId': 'item-1',
                'components': [
                  {
                    'stockItemId': 'stock-1',
                    'quantityInBaseUnit': 250,
                    'trackingMode': 'TRACKED',
                  },
                ],
              },
            },
            requestOptions: RequestOptions(
              path: '/v0/menu/items/item-1/composition/evaluate',
            ),
          ),
        );

        await api.upsertMenuItemComposition(
          menuItemId: 'item-1',
          baseComponents: const [
            MenuComponentDto(
              stockItemId: 'stock-1',
              quantityInBaseUnit: 250,
              trackingMode: 'TRACKED',
            ),
          ],
        );

        final evaluated = await api.evaluateMenuItemComposition(
          menuItemId: 'item-1',
          selectedModifierOptionIds: const ['opt-1'],
        );

        final upsertCaptured = verify(
          () => dio.put<void>(
            '/v0/menu/items/item-1/composition',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final upsertBody = Map<String, dynamic>.from(upsertCaptured[0] as Map);
        final upsertOptions = upsertCaptured[1] as Options;
        final upsertRequest = _idempotencyRequest(upsertOptions);

        expect(upsertBody['baseComponents'], [
          {
            'stockItemId': 'stock-1',
            'quantityInBaseUnit': 250.0,
            'trackingMode': 'TRACKED',
          },
        ]);
        expect(upsertRequest.actionKey, 'menu.composition.upsert');
        expect(upsertRequest.payload, {'menuItemId': 'item-1', ...upsertBody});

        verify(
          () => dio.post<dynamic>(
            '/v0/menu/items/item-1/composition/evaluate',
            data: {
              'selectedModifierOptionIds': ['opt-1'],
            },
          ),
        ).called(1);
        verifyNever(
          () => dio.post<dynamic>(
            '/v0/menu/items/item-1/composition/evaluate',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );
        expect(evaluated.menuItemId, 'item-1');
        expect(evaluated.components, hasLength(1));
      },
    );

    test(
      'modifier option effects upsert uses explicit endpoint and idempotency',
      () async {
        final dio = _MockDio();
        final api = MenuApi.real(dio);

        when(
          () => dio.put<void>(
            '/v0/menu/items/item-1/modifier-option-effects',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(
              path: '/v0/menu/items/item-1/modifier-option-effects',
            ),
          ),
        );

        await api.upsertMenuItemModifierOptionEffects(
          menuItemId: 'item-1',
          effects: const [
            MenuModifierOptionEffectDto(
              modifierOptionId: 'opt-1',
              components: [
                ModifierDeltaDto(
                  stockItemId: 'stock-2',
                  quantityDeltaInBaseUnit: 50,
                  trackingMode: 'TRACKED',
                ),
              ],
            ),
          ],
        );

        final captured = verify(
          () => dio.put<void>(
            '/v0/menu/items/item-1/modifier-option-effects',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final body = Map<String, dynamic>.from(captured[0] as Map);
        final options = captured[1] as Options;
        final request = _idempotencyRequest(options);

        expect(body['modifierOptionEffects'], [
          {
            'modifierOptionId': 'opt-1',
            'components': [
              {
                'stockItemId': 'stock-2',
                'quantityDeltaInBaseUnit': 50.0,
                'trackingMode': 'TRACKED',
              },
            ],
          },
        ]);
        expect(request.actionKey, 'menu.modifierOptionEffects.upsert');
        expect(request.payload, {'menuItemId': 'item-1', ...body});
      },
    );
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

Map<String, dynamic> _modifierGroupJson({
  required String id,
  required String name,
}) {
  return <String, dynamic>{
    'id': id,
    'tenantId': 'tenant-1',
    'name': name,
    'selectionMode': 'SINGLE',
    'minSelections': 0,
    'maxSelections': 1,
    'isRequired': false,
    'status': 'ACTIVE',
    'options': const <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _modifierOptionJson({
  required String id,
  required String groupId,
}) {
  return <String, dynamic>{
    'id': id,
    'groupId': groupId,
    'label': 'Large',
    'priceDelta': 0.5,
    'status': 'ACTIVE',
    'componentDeltas': const <Map<String, dynamic>>[],
  };
}
