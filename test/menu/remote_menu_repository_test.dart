import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/menu/data/dto/menu_branch_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_category_dto.dart';
import 'package:modular_pos/features/menu/data/dto/menu_item_dto.dart';
import 'package:modular_pos/features/menu/data/dto/modifier_group_dto.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/data/remote_menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';

class _MockMenuApi extends Mock implements MenuApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String>[]);
    registerFallbackValue(<int>[]);
  });

  group('RemoteMenuRepository', () {
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
  });
}
