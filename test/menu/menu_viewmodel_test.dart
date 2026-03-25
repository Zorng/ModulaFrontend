import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/menu/data/menu_cache_store.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../test_utils/riverpod_test_utils.dart';

class _MockMenuRepository extends Mock implements MenuRepository {}

final _sqliteAvailable = () {
  try {
    final db = sqlite3.sqlite3.openInMemory();
    db.dispose();
    return true;
  } catch (_) {
    return false;
  }
}();

class _FixedAuthTenantIdNotifier extends AuthTenantIdNotifier {
  _FixedAuthTenantIdNotifier(this._tenantId);

  final String _tenantId;

  @override
  String? build() => _tenantId;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const <MenuComponent>[]);
    registerFallbackValue(const <MenuModifierOptionEffect>[]);
  });

  group('MenuViewModel', () {
    group(
      'with sqlite cache store',
      () {
        test(
          'loadMenu shows cached bundle while remote refresh is in flight',
          () async {
            final repo = _MockMenuRepository();
            final database = AppDatabase(NativeDatabase.memory());
            addTearDown(database.close);
            final cacheStore = DriftMenuCacheStore(database);
            const scope = MenuCacheQuery(
              tenantId: 'tenant-1',
              scopeKey: 'management|active|all',
              readLane: MenuReadLane.management,
              status: 'active',
            );
            await cacheStore.write(
              scope: scope,
              bundle: const MenuDataBundle(
                items: [
                  MenuItem(
                    id: 'item-1',
                    name: 'Latte',
                    categoryId: 'cat-1',
                    price: 2.5,
                  ),
                ],
                categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
                modifierGroups: [
                  ModifierGroup(
                    id: 'group-1',
                    name: 'Milk',
                    selectionType: 'single',
                    pricingBehavior: 'addon',
                    options: [],
                  ),
                ],
                branches: [],
              ),
            );

            final completer = Completer<MenuDataBundle>();
            when(
              () => repo.fetchMenuData(
                readLane: MenuReadLane.management,
                status: 'active',
                branchIdFilter: null,
              ),
            ).thenAnswer((_) => completer.future);

            final container = createTestContainer(
              overrides: [
                appDatabaseProvider.overrideWithValue(database),
                menuRepositoryProvider.overrideWithValue(repo),
                authTenantIdProvider.overrideWith(
                  () => _FixedAuthTenantIdNotifier('tenant-1'),
                ),
              ],
            );

            final notifier = container.read(menuViewModelProvider.notifier);
            final loadFuture = notifier.loadMenu();
            await Future<void>.delayed(Duration.zero);

            final loadingState = container.read(menuViewModelProvider);
            expect(loadingState.isLoading, isTrue);
            expect(loadingState.allItems.single.id, 'item-1');
            expect(loadingState.categories.single.id, 'cat-1');

            completer.complete(
              const MenuDataBundle(
                items: [
                  MenuItem(
                    id: 'item-2',
                    name: 'Mocha',
                    categoryId: 'cat-2',
                    price: 3,
                  ),
                ],
                categories: [MenuCategory(id: 'cat-2', name: 'Coffee 2')],
                modifierGroups: [],
                branches: [],
              ),
            );
            await loadFuture;

            final state = container.read(menuViewModelProvider);
            expect(state.isLoading, isFalse);
            expect(state.allItems.single.id, 'item-2');
          },
        );

        test('loadMenu keeps cached bundle when refresh fails', () async {
          final repo = _MockMenuRepository();
          final database = AppDatabase(NativeDatabase.memory());
          addTearDown(database.close);
          final cacheStore = DriftMenuCacheStore(database);
          await cacheStore.write(
            scope: const MenuCacheQuery(
              tenantId: 'tenant-1',
              scopeKey: 'management|active|all',
              readLane: MenuReadLane.management,
              status: 'active',
            ),
            bundle: const MenuDataBundle(
              items: [
                MenuItem(
                  id: 'item-1',
                  name: 'Latte',
                  categoryId: 'cat-1',
                  price: 2.5,
                ),
              ],
              categories: [],
              modifierGroups: [],
              branches: [],
            ),
          );
          when(
            () => repo.fetchMenuData(
              readLane: MenuReadLane.management,
              status: 'active',
              branchIdFilter: null,
            ),
          ).thenThrow(
            const ApiClientException(
              message: 'offline',
              code: 'OFFLINE_UNREACHABLE',
            ),
          );

          final container = createTestContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(database),
              menuRepositoryProvider.overrideWithValue(repo),
              authTenantIdProvider.overrideWith(
                () => _FixedAuthTenantIdNotifier('tenant-1'),
              ),
            ],
          );

          final notifier = container.read(menuViewModelProvider.notifier);
          await notifier.loadMenu();

          final state = container.read(menuViewModelProvider);
          expect(state.allItems.single.id, 'item-1');
          expect(state.errorCode, 'OFFLINE_UNREACHABLE');
          expect(state.isLoading, isFalse);
        });

        test(
          'loadMenu stops loading and keeps cached bundle when refresh times out',
          () async {
            final repo = _MockMenuRepository();
            final database = AppDatabase(NativeDatabase.memory());
            addTearDown(database.close);
            final cacheStore = DriftMenuCacheStore(database);
            await cacheStore.write(
              scope: const MenuCacheQuery(
                tenantId: 'tenant-1',
                scopeKey: 'management|active|all',
                readLane: MenuReadLane.management,
                status: 'active',
              ),
              bundle: const MenuDataBundle(
                items: [
                  MenuItem(
                    id: 'item-1',
                    name: 'Latte',
                    categoryId: 'cat-1',
                    price: 2.5,
                  ),
                ],
                categories: [],
                modifierGroups: [],
                branches: [],
              ),
            );
            final completer = Completer<MenuDataBundle>();
            when(
              () => repo.fetchMenuData(
                readLane: MenuReadLane.management,
                status: 'active',
                branchIdFilter: null,
              ),
            ).thenAnswer((_) => completer.future);

            final container = createTestContainer(
              overrides: [
                appDatabaseProvider.overrideWithValue(database),
                menuRepositoryProvider.overrideWithValue(repo),
                authTenantIdProvider.overrideWith(
                  () => _FixedAuthTenantIdNotifier('tenant-1'),
                ),
                menuRequestTimeoutProvider.overrideWithValue(
                  const Duration(milliseconds: 10),
                ),
              ],
            );

            final notifier = container.read(menuViewModelProvider.notifier);
            await notifier.loadMenu();

            final state = container.read(menuViewModelProvider);
            expect(state.isLoading, isFalse);
            expect(state.allItems.single.id, 'item-1');
            expect(state.errorCode, 'OFFLINE_UNREACHABLE');
          },
        );
      },
      skip: _sqliteAvailable ? false : 'sqlite3.dll not available for Drift tests on this machine',
    );

    test(
      'filterByStatus reloads archived items and preserves branch/search filters',
      () async {
        final repo = _MockMenuRepository();
        when(
          () => repo.fetchMenuData(
            readLane: MenuReadLane.management,
            status: 'archived',
            branchIdFilter: 'branch-1',
          ),
        ).thenAnswer(
          (_) async => const MenuDataBundle(
            items: [
              MenuItem(
                id: 'item-archived',
                name: 'Old Latte',
                categoryId: 'cat-1',
                price: 2.5,
                basePrice: 2.5,
                status: 'ARCHIVED',
                visibleBranchIds: ['branch-1'],
                branchIds: ['branch-1'],
                isActive: false,
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

        notifier.state = const MenuState(
          isLoading: false,
          selectedBranchId: 'branch-1',
          selectedStatus: 'active',
          searchQuery: 'old',
        );

        await notifier.filterByStatus('archived');

        final state = container.read(menuViewModelProvider);
        expect(state.selectedStatus, 'archived');
        expect(state.selectedBranchId, 'branch-1');
        expect(state.searchQuery, 'old');
        expect(state.filteredItems, hasLength(1));
        expect(state.filteredItems.first.id, 'item-archived');

        verify(
          () => repo.fetchMenuData(
            readLane: MenuReadLane.management,
            status: 'archived',
            branchIdFilter: 'branch-1',
          ),
        ).called(1);
      },
    );

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
          selectedStatus: 'active',
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
      expect(state.baseCompositionByItemId['item-1'], hasLength(1));
      expect(
        state.baseCompositionByItemId['item-1']!.first.stockItemId,
        'stock-1',
      );
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
      expect(state.evaluatedCompositionByItemId['item-1'], isNotNull);
      expect(
        state
            .compositionEvaluationByItem['item-1']!
            .components
            .first
            .stockItemId,
        'stock-1',
      );
    });

    test('upsertItemModifierOptionEffects stores explicit effect state', () async {
      final repo = _MockMenuRepository();
      when(
        () => repo.upsertMenuItemModifierOptionEffects(
          menuItemId: 'item-1',
          effects: any(named: 'effects'),
        ),
      ).thenAnswer((_) async {});

      final container = createTestContainer(
        overrides: [menuRepositoryProvider.overrideWithValue(repo)],
      );
      final notifier = container.read(menuViewModelProvider.notifier);

      await notifier.upsertItemModifierOptionEffects(
        menuItemId: 'item-1',
        effects: const [
          MenuModifierOptionEffect(
            modifierOptionId: 'opt-1',
            components: [
              ModifierDelta(
                stockItemId: 'stock-2',
                quantityDeltaInBaseUnit: -50,
                trackingMode: 'TRACKED',
              ),
            ],
          ),
        ],
      );

      final state = container.read(menuViewModelProvider);
      expect(state.modifierOptionEffectsByItemId['item-1'], hasLength(1));
      expect(
        state.modifierOptionEffectsByItemId['item-1']!.first.modifierOptionId,
        'opt-1',
      );
      expect(
        state.modifierOptionEffectsErrorsByItemId.containsKey('item-1'),
        isFalse,
      );
      verify(
        () => repo.upsertMenuItemModifierOptionEffects(
          menuItemId: 'item-1',
          effects: any(named: 'effects'),
        ),
      ).called(1);
    });
  });
}
