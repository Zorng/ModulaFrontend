import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockMenuRepository extends Mock implements MenuRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const <MenuComponent>[]);
  });

  group('MenuViewModel', () {
    test(
      'setMenuItemVisibility updates item branches, reloads menu, and clears operation error',
      () async {
        final repo = _MockMenuRepository();
        when(
          () => repo.setMenuItemVisibility(
            menuItemId: 'item-1',
            visibleBranchIds: ['branch-2'],
          ),
        ).thenAnswer((_) async {});
        when(
          () => repo.fetchMenuData(
            readLane: MenuReadLane.management,
            status: 'active',
            branchIdFilter: null,
          ),
        ).thenAnswer(
          (_) async => const MenuDataBundle(
            items: [
              MenuItem(
                id: 'item-1',
                name: 'Latte',
                categoryId: 'cat-1',
                price: 2.5,
                basePrice: 2.5,
                visibleBranchIds: ['branch-2'],
                branchIds: ['branch-2'],
              ),
            ],
            categories: [],
            modifierGroups: [],
            branches: [],
          ),
        );

        final container = createTestContainer(
          overrides: [menuRepositoryProvider.overrideWithValue(repo)],
        );
        final notifier = container.read(menuViewModelProvider.notifier);

        const seededItem = MenuItem(
          id: 'item-1',
          name: 'Latte',
          categoryId: 'cat-1',
          price: 2.5,
          basePrice: 2.5,
          visibleBranchIds: ['branch-1'],
          branchIds: ['branch-1'],
        );

        notifier.state = const MenuState(
          isLoading: false,
          allItems: [seededItem],
          filteredItems: [seededItem],
          selectedBranchId: 'all',
          error: 'old-error',
          errorCode: 'OLD_CODE',
        );

        await notifier.setMenuItemVisibility(
          menuItemId: 'item-1',
          visibleBranchIds: ['branch-2'],
        );

        final state = container.read(menuViewModelProvider);
        expect(state.error, isNull);
        expect(state.errorCode, isNull);
        expect(state.allItems.first.visibleBranchIds, ['branch-2']);
        expect(state.allItems.first.branchIds, ['branch-2']);
        expect(state.filteredItems.first.visibleBranchIds, ['branch-2']);

        verify(
          () => repo.setMenuItemVisibility(
            menuItemId: 'item-1',
            visibleBranchIds: ['branch-2'],
          ),
        ).called(1);
        verify(
          () => repo.fetchMenuData(
            readLane: MenuReadLane.management,
            status: 'active',
            branchIdFilter: null,
          ),
        ).called(1);
      },
    );

    test(
      'setMenuItemVisibility maps ApiClientException to deterministic state',
      () async {
        final repo = _MockMenuRepository();
        when(
          () => repo.setMenuItemVisibility(
            menuItemId: 'item-1',
            visibleBranchIds: ['branch-2'],
          ),
        ).thenThrow(
          const ApiClientException(
            message: 'No branch access',
            code: 'NO_BRANCH_ACCESS',
            statusCode: 403,
          ),
        );

        final container = createTestContainer(
          overrides: [menuRepositoryProvider.overrideWithValue(repo)],
        );
        final notifier = container.read(menuViewModelProvider.notifier);

        const seededItem = MenuItem(
          id: 'item-1',
          name: 'Latte',
          categoryId: 'cat-1',
          price: 2.5,
          basePrice: 2.5,
          visibleBranchIds: ['branch-1'],
          branchIds: ['branch-1'],
        );

        notifier.state = const MenuState(
          isLoading: false,
          allItems: [seededItem],
          filteredItems: [seededItem],
        );

        expect(
          () => notifier.setMenuItemVisibility(
            menuItemId: 'item-1',
            visibleBranchIds: ['branch-2'],
          ),
          throwsA(isA<ApiClientException>()),
        );

        final state = container.read(menuViewModelProvider);
        expect(state.error, 'No branch access');
        expect(state.errorCode, 'NO_BRANCH_ACCESS');
        expect(state.allItems.first.visibleBranchIds, ['branch-1']);

        verify(
          () => repo.setMenuItemVisibility(
            menuItemId: 'item-1',
            visibleBranchIds: ['branch-2'],
          ),
        ).called(1);
        verifyNever(
          () => repo.fetchMenuData(
            readLane: MenuReadLane.management,
            status: 'active',
            branchIdFilter: null,
          ),
        );
      },
    );

    test('loadItemComposition stores base components by item id', () async {
      final repo = _MockMenuRepository();
      when(() => repo.fetchMenuItemComposition('item-1')).thenAnswer(
        (_) async => const [
          MenuComponent(
            stockItemId: 'stock-1',
            quantityInBaseUnit: 250,
            trackingMode: 'TRACKED',
          ),
        ],
      );

      final container = createTestContainer(
        overrides: [menuRepositoryProvider.overrideWithValue(repo)],
      );
      final notifier = container.read(menuViewModelProvider.notifier);

      await notifier.loadItemComposition('item-1');

      final state = container.read(menuViewModelProvider);
      expect(state.compositionLoadedByItem['item-1'], isTrue);
      expect(state.compositionByItem['item-1'], hasLength(1));
      expect(state.compositionByItem['item-1']!.first.stockItemId, 'stock-1');
      expect(state.compositionErrors.containsKey('item-1'), isFalse);
    });

    test(
      'upsertItemComposition maps entitlement error code to deterministic composition state',
      () async {
        final repo = _MockMenuRepository();
        when(
          () => repo.upsertMenuItemComposition(
            menuItemId: 'item-1',
            baseComponents: any(named: 'baseComponents'),
          ),
        ).thenThrow(
          const ApiClientException(
            message: 'blocked',
            code: 'INVENTORY_ENTITLEMENT_REQUIRED_FOR_TRACKED_COMPONENTS',
            statusCode: 403,
          ),
        );

        final container = createTestContainer(
          overrides: [menuRepositoryProvider.overrideWithValue(repo)],
        );
        final notifier = container.read(menuViewModelProvider.notifier);

        await expectLater(
          notifier.upsertItemComposition(
            menuItemId: 'item-1',
            baseComponents: const [
              MenuComponent(
                stockItemId: 'stock-1',
                quantityInBaseUnit: 100,
                trackingMode: 'TRACKED',
              ),
            ],
          ),
          throwsA(isA<ApiClientException>()),
        );

        final state = container.read(menuViewModelProvider);
        expect(
          state.compositionErrors['item-1'],
          'Tracked components require inventory entitlement.',
        );
        expect(
          state.compositionErrorCodes['item-1'],
          'INVENTORY_ENTITLEMENT_REQUIRED_FOR_TRACKED_COMPONENTS',
        );
      },
    );

    test('evaluateItemComposition stores evaluated preview', () async {
      final repo = _MockMenuRepository();
      when(
        () => repo.evaluateMenuItemComposition(
          menuItemId: 'item-1',
          selectedModifierOptionIds: ['opt-1'],
        ),
      ).thenAnswer(
        (_) async => const MenuCompositionEvaluate(
          menuItemId: 'item-1',
          components: [
            MenuComponent(
              stockItemId: 'stock-1',
              quantityInBaseUnit: 300,
              trackingMode: 'TRACKED',
            ),
          ],
        ),
      );

      final container = createTestContainer(
        overrides: [menuRepositoryProvider.overrideWithValue(repo)],
      );
      final notifier = container.read(menuViewModelProvider.notifier);

      final evaluated = await notifier.evaluateItemComposition(
        menuItemId: 'item-1',
        selectedModifierOptionIds: const ['opt-1'],
      );

      expect(evaluated.menuItemId, 'item-1');
      expect(evaluated.components, hasLength(1));
      final state = container.read(menuViewModelProvider);
      expect(state.compositionEvaluationByItem['item-1'], isNotNull);
      expect(
        state
            .compositionEvaluationByItem['item-1']!
            .components
            .first
            .stockItemId,
        'stock-1',
      );
    });
  });
}
