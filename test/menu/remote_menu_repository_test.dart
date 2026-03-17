import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_composition_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_with_modifiers_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/data/remote_menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class _MockMenuApi extends Mock implements MenuApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String>[]);
    registerFallbackValue(<int>[]);
    registerFallbackValue(<MenuComponentDto>[]);
  });

  group('RemoteMenuRepository', () {
    test('fetchCategoriesOnly filters active and archived categories', () async {
      final api = _MockMenuApi();
      final repository = RemoteMenuRepository(api);

      when(
        () => api.fetchCategories(status: any(named: 'status')),
      ).thenAnswer(
        (_) async => const [
          MenuCategoryDto(
            id: 'cat-active-1',
            tenantId: 'tenant-1',
            name: 'Coffee',
            status: 'ACTIVE',
            description: '',
            isActive: true,
            displayOrder: 1,
            createdAt: null,
            updatedAt: null,
          ),
          MenuCategoryDto(
            id: 'cat-active-2',
            tenantId: 'tenant-1',
            name: 'Tea',
            status: 'ACTIVE',
            description: '',
            isActive: true,
            displayOrder: 2,
            createdAt: null,
            updatedAt: null,
          ),
          MenuCategoryDto(
            id: 'cat-archived-1',
            tenantId: 'tenant-1',
            name: 'Legacy',
            status: 'ARCHIVED',
            description: '',
            isActive: false,
            displayOrder: 3,
            createdAt: null,
            updatedAt: null,
          ),
        ],
      );

      final active = await repository.fetchCategoriesOnly(status: 'active');
      final archived = await repository.fetchCategoriesOnly(status: 'archived');

      expect(
        active.map((c) => c.id).toList(),
        ['cat-active-1', 'cat-active-2'],
      );
      expect(archived.map((c) => c.id).toList(), ['cat-archived-1']);

      verify(() => api.fetchCategories(status: 'active')).called(1);
      verify(() => api.fetchCategories(status: 'archived')).called(1);
    });

    test(
      'fetchMenuData management lane applies status filter with no read fallback',
      () async {
        final api = _MockMenuApi();
        final repository = RemoteMenuRepository(api);

        when(() => api.fetchBranches()).thenAnswer(
          (_) async => const [
            MenuBranchDto(id: 'branch-1', name: 'Main'),
            MenuBranchDto(id: 'branch-2', name: 'Kiosk'),
          ],
        );

        when(
          () => api.fetchCategories(status: any(named: 'status')),
        ).thenAnswer(
          (_) async => const [
            MenuCategoryDto(
              id: 'cat-active',
              tenantId: 'tenant-1',
              name: 'Coffee',
              status: 'ACTIVE',
              description: '',
              isActive: true,
              displayOrder: 1,
              createdAt: null,
              updatedAt: null,
            ),
            MenuCategoryDto(
              id: 'cat-archived',
              tenantId: 'tenant-1',
              name: 'Legacy',
              status: 'ARCHIVED',
              description: '',
              isActive: false,
              displayOrder: null,
              createdAt: null,
              updatedAt: null,
            ),
          ],
        );

        when(
          () => api.fetchModifierGroups(status: any(named: 'status')),
        ).thenAnswer(
          (_) async => const [
            ModifierGroupDto(
              id: 'group-1',
              tenantId: 'tenant-1',
              name: 'Milk',
              selectionMode: 'SINGLE',
              minSelections: 0,
              maxSelections: 1,
              isRequired: false,
              status: 'ACTIVE',
              options: <ModifierOptionDto>[],
              selectionType: 'single',
              pricingBehavior: 'addon',
              defaultOptionId: null,
              isActive: true,
            ),
            ModifierGroupDto(
              id: 'group-archived',
              tenantId: 'tenant-1',
              name: 'Legacy Group',
              selectionMode: 'SINGLE',
              minSelections: 0,
              maxSelections: 1,
              isRequired: false,
              status: 'ARCHIVED',
              options: <ModifierOptionDto>[],
              selectionType: 'single',
              pricingBehavior: 'addon',
              defaultOptionId: null,
              isActive: false,
            ),
          ],
        );

        when(
          () => api.fetchMenuItems(
            includeAllBranches: any(named: 'includeAllBranches'),
            status: any(named: 'status'),
            categoryId: any(named: 'categoryId'),
            search: any(named: 'search'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            branchId: any(named: 'branchId'),
          ),
        ).thenAnswer((invocation) async {
          expect(
            invocation.namedArguments[#includeAllBranches] as bool,
            isTrue,
          );
          return const [
            MenuItemDto(
              id: 'item-1',
              tenantId: 'tenant-1',
              name: 'Latte',
              categoryId: 'cat-active',
              basePrice: 2.5,
              status: 'ACTIVE',
              priceUsd: 2.5,
              imageUrl: null,
              modifierGroupIds: <String>['group-1'],
              description: '',
              visibleBranchIds: <String>['branch-1'],
              branchIds: <String>['branch-1'],
              createdAt: null,
              updatedAt: null,
              isActive: true,
            ),
            MenuItemDto(
              id: 'item-archived',
              tenantId: 'tenant-1',
              name: 'Old',
              categoryId: 'cat-active',
              basePrice: 1,
              status: 'ARCHIVED',
              priceUsd: 1,
              imageUrl: null,
              modifierGroupIds: <String>[],
              description: '',
              visibleBranchIds: <String>['branch-2'],
              branchIds: <String>['branch-2'],
              createdAt: null,
              updatedAt: null,
              isActive: false,
            ),
          ];
        });

        final bundle = await repository.fetchMenuData(
          readLane: MenuReadLane.management,
          status: 'active',
          branchIdFilter: 'branch-1',
        );

        expect(bundle.items.length, 1);
        expect(bundle.items.first.id, 'item-1');
        expect(bundle.items.first.branchIds, contains('branch-1'));

        expect(bundle.categories.map((c) => c.id).toList(), ['cat-active']);
        expect(bundle.modifierGroups.length, 1);
        expect(bundle.modifierGroups.first.id, 'group-1');
        expect(bundle.modifierGroups.first.options, isEmpty);
        expect(bundle.branches.map((b) => b.id).toList(), [
          'branch-1',
          'branch-2',
        ]);

        verify(
          () => api.fetchMenuItems(
            includeAllBranches: true,
            status: 'active',
            categoryId: null,
            search: null,
            limit: null,
            offset: null,
            branchId: 'branch-1',
          ),
        ).called(1);
      },
    );

    test(
      'fetchMenuData propagates read errors without silent fallback',
      () async {
        final api = _MockMenuApi();
        final repository = RemoteMenuRepository(api);

        when(
          () => api.fetchBranches(),
        ).thenAnswer((_) async => const <MenuBranchDto>[]);
        when(
          () => api.fetchCategories(status: any(named: 'status')),
        ).thenAnswer((_) async => const <MenuCategoryDto>[]);
        when(
          () => api.fetchModifierGroups(status: any(named: 'status')),
        ).thenAnswer((_) async => const <ModifierGroupDto>[]);
        when(
          () => api.fetchMenuItems(
            includeAllBranches: any(named: 'includeAllBranches'),
            status: any(named: 'status'),
            categoryId: any(named: 'categoryId'),
            search: any(named: 'search'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            branchId: any(named: 'branchId'),
          ),
        ).thenThrow(const MenuApiException('read-failed'));

        await expectLater(
          repository.fetchMenuData(readLane: MenuReadLane.management),
          throwsA(isA<MenuApiException>()),
        );
      },
    );

    test('updateCategory includes status for restore/archive flows', () async {
      final api = _MockMenuApi();
      final repository = RemoteMenuRepository(api);

      when(() => api.updateCategory(any())).thenAnswer(
        (_) async => const MenuCategoryDto(
          id: 'cat-1',
          tenantId: 'tenant-1',
          name: 'Coffee',
          status: 'ACTIVE',
          description: 'Hot drinks',
          isActive: true,
          displayOrder: 1,
          createdAt: null,
          updatedAt: null,
        ),
      );

      await repository.updateCategory(
        const MenuCategory(
          id: 'cat-1',
          tenantId: 'tenant-1',
          name: 'Coffee',
          status: 'ACTIVE',
          description: 'Hot drinks',
        ),
      );

      final payload =
          verify(() => api.updateCategory(captureAny())).captured.single
              as Map<String, dynamic>;

      expect(payload['id'], 'cat-1');
      expect(payload['name'], 'Coffee');
      expect(payload['description'], 'Hot drinks');
      expect(payload['status'], 'ACTIVE');
    });

    test(
      'createMenuItem preserves requested visibility and modifier ids',
      () async {
        final api = _MockMenuApi();
        final repository = RemoteMenuRepository(api);

        when(
          () => api.createMenuItem(
            any(),
            imagePath: any(named: 'imagePath'),
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer(
          (_) async => const MenuItemDto(
            id: 'item-created',
            tenantId: 'tenant-1',
            name: 'New Item',
            categoryId: 'cat-1',
            basePrice: 4,
            status: 'ACTIVE',
            priceUsd: 4,
            imageUrl: null,
            modifierGroupIds: <String>[],
            description: '',
            visibleBranchIds: <String>[],
            branchIds: <String>[],
            createdAt: null,
            updatedAt: null,
            isActive: true,
          ),
        );

        const newItem = MenuItem(
          id: '',
          tenantId: 'tenant-1',
          name: 'New Item',
          categoryId: 'cat-1',
          price: 4,
          basePrice: 4,
          modifierGroupIds: ['group-1'],
          visibleBranchIds: ['branch-1', 'branch-2'],
          branchIds: ['branch-1', 'branch-2'],
        );

        final created = await repository.createMenuItem(newItem);

        expect(created.id, 'item-created');
        expect(created.modifierGroupIds, ['group-1']);
        expect(created.visibleBranchIds, ['branch-1', 'branch-2']);
        expect(created.branchIds, ['branch-1', 'branch-2']);

        verify(
          () => api.createMenuItem(
            any(),
            imagePath: any(named: 'imagePath'),
            imageBytes: any(named: 'imageBytes'),
          ),
        ).called(1);
      },
    );

    test('setMenuItemAvailability maps to visibility payload', () async {
      final api = _MockMenuApi();
      final repository = RemoteMenuRepository(api);

      when(
        () => api.setItemVisibility(
          menuItemId: any(named: 'menuItemId'),
          visibleBranchIds: any(named: 'visibleBranchIds'),
        ),
      ).thenAnswer((_) async {});

      await repository.setMenuItemAvailability(
        menuItemId: 'item-1',
        branchId: 'branch-1',
        isAvailable: true,
      );

      verify(
        () => api.setItemVisibility(
          menuItemId: 'item-1',
          visibleBranchIds: ['branch-1'],
        ),
      ).called(1);

      await repository.setMenuItemAvailability(
        menuItemId: 'item-1',
        branchId: 'branch-1',
        isAvailable: false,
      );

      verify(
        () => api.setItemVisibility(
          menuItemId: 'item-1',
          visibleBranchIds: <String>[],
        ),
      ).called(1);
    });

    test('createModifierGroup maps selection mode and option deltas', () async {
      final api = _MockMenuApi();
      final repository = RemoteMenuRepository(api);

      when(() => api.createModifierGroup(any())).thenAnswer(
        (_) async => const ModifierGroupDto(
          id: 'group-1',
          tenantId: 'tenant-1',
          name: 'Size',
          selectionMode: 'MULTI',
          minSelections: 1,
          maxSelections: 2,
          isRequired: true,
          status: 'ACTIVE',
          options: <ModifierOptionDto>[],
          selectionType: 'multiple',
          pricingBehavior: 'addon',
          defaultOptionId: null,
          isActive: true,
        ),
      );
      when(() => api.addModifierOption(any())).thenAnswer(
        (_) async => const ModifierOptionDto(
          id: 'opt-1',
          groupId: 'group-1',
          label: 'Large',
          priceDelta: 0.5,
          status: 'ACTIVE',
          componentDeltas: <ModifierDeltaDto>[],
          priceAdjustmentUsd: 0.5,
          isDefault: false,
          isActive: true,
        ),
      );

      const input = ModifierGroup(
        id: '',
        name: 'Size',
        selectionType: 'multiple',
        pricingBehavior: 'addon',
        selectionMode: 'MULTI',
        minSelections: 1,
        maxSelections: 2,
        isRequired: true,
        options: [
          ModifierOption(
            id: '',
            name: 'Large',
            price: 0.5,
            componentDeltas: [
              ModifierDelta(
                stockItemId: 'stock-1',
                quantityDeltaInBaseUnit: 100,
                trackingMode: 'TRACKED',
              ),
            ],
          ),
        ],
      );

      final created = await repository.createModifierGroup(input);

      final groupPayload =
          verify(() => api.createModifierGroup(captureAny())).captured.single
              as Map<String, dynamic>;
      final optionPayload =
          verify(() => api.addModifierOption(captureAny())).captured.single
              as Map<String, dynamic>;

      expect(groupPayload['selectionMode'], 'MULTI');
      expect(groupPayload['minSelections'], 1);
      expect(groupPayload['maxSelections'], 2);
      expect(groupPayload['isRequired'], isTrue);

      expect(optionPayload['groupId'], 'group-1');
      expect(optionPayload['label'], 'Large');
      expect(optionPayload['priceDelta'], 0.5);
      expect(optionPayload['componentDeltas'], [
        {
          'stockItemId': 'stock-1',
          'quantityDeltaInBaseUnit': 100.0,
          'trackingMode': 'TRACKED',
        },
      ]);
      expect(created.options, hasLength(1));
    });

    test(
      'updateModifierGroup applies option delta create/update/archive calls',
      () async {
        final api = _MockMenuApi();
        final repository = RemoteMenuRepository(api);

        when(() => api.updateModifierGroup(any())).thenAnswer(
          (_) async => const ModifierGroupDto(
            id: 'group-1',
            tenantId: 'tenant-1',
            name: 'Size',
            selectionMode: 'SINGLE',
            minSelections: 0,
            maxSelections: 1,
            isRequired: false,
            status: 'ACTIVE',
            options: <ModifierOptionDto>[],
            selectionType: 'single',
            pricingBehavior: 'addon',
            defaultOptionId: null,
            isActive: true,
          ),
        );
        when(() => api.updateModifierOption(any(), any())).thenAnswer(
          (_) async => const ModifierOptionDto(
            id: 'opt-existing',
            groupId: 'group-1',
            label: 'M',
            priceDelta: 0.2,
            status: 'ACTIVE',
            componentDeltas: <ModifierDeltaDto>[],
            priceAdjustmentUsd: 0.2,
            isDefault: false,
            isActive: true,
          ),
        );
        when(() => api.addModifierOption(any())).thenAnswer(
          (_) async => const ModifierOptionDto(
            id: 'opt-new',
            groupId: 'group-1',
            label: 'XL',
            priceDelta: 0.5,
            status: 'ACTIVE',
            componentDeltas: <ModifierDeltaDto>[],
            priceAdjustmentUsd: 0.5,
            isDefault: false,
            isActive: true,
          ),
        );
        when(
          () => api.deleteModifierOption(any(), groupId: any(named: 'groupId')),
        ).thenAnswer((_) async {});

        const previous = ModifierGroup(
          id: 'group-1',
          name: 'Size',
          selectionType: 'single',
          pricingBehavior: 'addon',
          selectionMode: 'SINGLE',
          minSelections: 0,
          maxSelections: 1,
          options: [
            ModifierOption(id: 'opt-existing', name: 'M', price: 0.1),
            ModifierOption(id: 'opt-removed', name: 'L', price: 0.3),
          ],
        );

        const updated = ModifierGroup(
          id: 'group-1',
          name: 'Size',
          selectionType: 'single',
          pricingBehavior: 'addon',
          selectionMode: 'SINGLE',
          minSelections: 0,
          maxSelections: 1,
          options: [
            ModifierOption(
              id: 'opt-existing',
              name: 'M',
              price: 0.2,
              componentDeltas: [
                ModifierDelta(
                  stockItemId: 'stock-1',
                  quantityDeltaInBaseUnit: 80,
                  trackingMode: 'TRACKED',
                ),
              ],
            ),
            ModifierOption(id: '', name: 'XL', price: 0.5),
          ],
        );

        await repository.updateModifierGroup(updated, previous: previous);

        final updateOptionCaptured =
            verify(
                  () => api.updateModifierOption('opt-existing', captureAny()),
                ).captured.single
                as Map<String, dynamic>;
        final addOptionCaptured =
            verify(() => api.addModifierOption(captureAny())).captured.single
                as Map<String, dynamic>;

        expect(updateOptionCaptured['groupId'], 'group-1');
        expect(updateOptionCaptured['label'], 'M');
        expect(updateOptionCaptured['priceDelta'], 0.2);
        expect(updateOptionCaptured['componentDeltas'], [
          {
            'stockItemId': 'stock-1',
            'quantityDeltaInBaseUnit': 80.0,
            'trackingMode': 'TRACKED',
          },
        ]);

        expect(addOptionCaptured['groupId'], 'group-1');
        expect(addOptionCaptured['label'], 'XL');
        expect(addOptionCaptured['priceDelta'], 0.5);

        verify(
          () => api.deleteModifierOption('opt-removed', groupId: 'group-1'),
        ).called(1);
      },
    );

    test(
      'fetchMenuItemComposition maps baseComponents from detail payload',
      () async {
        final api = _MockMenuApi();
        final repository = RemoteMenuRepository(api);

        when(() => api.fetchMenuItemWithModifiers('item-1')).thenAnswer(
          (_) async => MenuItemWithModifiersDto.fromJson({
            'id': 'item-1',
            'tenantId': 'tenant-1',
            'name': 'Latte',
            'categoryId': 'cat-1',
            'basePrice': 2.5,
            'status': 'ACTIVE',
            'modifierGroups': const [],
            'baseComponents': [
              {
                'stockItemId': 'stock-1',
                'quantityInBaseUnit': 250,
                'trackingMode': 'TRACKED',
              },
            ],
          }),
        );

        final components = await repository.fetchMenuItemComposition('item-1');

        expect(components, hasLength(1));
        expect(components.first.stockItemId, 'stock-1');
        expect(components.first.quantityInBaseUnit, 250);
        expect(components.first.trackingMode, 'TRACKED');
      },
    );

    test('upsert/evaluate composition map payloads and result', () async {
      final api = _MockMenuApi();
      final repository = RemoteMenuRepository(api);

      when(
        () => api.upsertMenuItemComposition(
          menuItemId: any(named: 'menuItemId'),
          baseComponents: any(named: 'baseComponents'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => api.evaluateMenuItemComposition(
          menuItemId: any(named: 'menuItemId'),
          selectedModifierOptionIds: any(named: 'selectedModifierOptionIds'),
        ),
      ).thenAnswer(
        (_) async => const MenuCompositionEvaluateDto(
          menuItemId: 'item-1',
          components: [
            MenuComponentDto(
              stockItemId: 'stock-1',
              quantityInBaseUnit: 300,
              trackingMode: 'TRACKED',
            ),
          ],
        ),
      );

      await repository.upsertMenuItemComposition(
        menuItemId: 'item-1',
        baseComponents: const [
          MenuComponent(
            stockItemId: 'stock-1',
            quantityInBaseUnit: 250,
            trackingMode: 'TRACKED',
          ),
        ],
      );
      final evaluated = await repository.evaluateMenuItemComposition(
        menuItemId: 'item-1',
        selectedModifierOptionIds: const ['opt-1'],
      );

      final captured =
          verify(
                () => api.upsertMenuItemComposition(
                  menuItemId: 'item-1',
                  baseComponents: captureAny(named: 'baseComponents'),
                ),
              ).captured.single
              as List<MenuComponentDto>;

      expect(captured, hasLength(1));
      expect(captured.first.stockItemId, 'stock-1');
      expect(captured.first.quantityInBaseUnit, 250);
      expect(captured.first.trackingMode, 'TRACKED');

      verify(
        () => api.evaluateMenuItemComposition(
          menuItemId: 'item-1',
          selectedModifierOptionIds: ['opt-1'],
        ),
      ).called(1);

      expect(evaluated.menuItemId, 'item-1');
      expect(evaluated.components, hasLength(1));
    });
  });
}
