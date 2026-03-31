import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/features/menu/data/menu_repository.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

import '../test_utils/pump_app.dart';

class _StaticMenuViewModel extends MenuViewModel {
  _StaticMenuViewModel(this._state);

  final MenuState _state;

  @override
  MenuState build() => _state;

  @override
  Future<void> loadMenu({
    String? branchId,
    String? status,
    MenuReadLane readLane = MenuReadLane.management,
  }) async {}
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
}

void _setNarrowViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1000, 800);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

List<MenuItem> _menuItems(int count) {
  return List<MenuItem>.generate(
    count,
    (index) => MenuItem(
      id: 'item-${index + 1}',
      name: 'Item ${index + 1}',
      categoryId: 'cat-1',
      price: index + 1,
    ),
    growable: false,
  );
}

void main() {
  testWidgets(
    'MenuPage keeps cached items visible and shows passive freshness banner',
    (tester) async {
      await pumpApp(
        tester,
        const MenuPage(),
        overrides: [
          menuViewModelProvider.overrideWith(
            () => _StaticMenuViewModel(
              const MenuState(
                isLoading: false,
                filteredItems: [
                  MenuItem(
                    id: 'item-1',
                    name: 'Latte',
                    categoryId: 'cat-1',
                    price: 2.5,
                  ),
                ],
                allItems: [
                  MenuItem(
                    id: 'item-1',
                    name: 'Latte',
                    categoryId: 'cat-1',
                    price: 2.5,
                  ),
                ],
                categories: [MenuCategory(id: 'cat-1', name: 'Coffee')],
                error: 'offline',
                errorCode: 'OFFLINE_UNREACHABLE',
              ),
            ),
          ),
          branchWorkspaceSyncFreshnessProvider.overrideWith(
            (ref) async => const SyncWorkspaceFreshness(
              kind: SyncWorkspaceFreshnessKind.staleUsable,
              message: 'Offline: showing last synced workspace data.',
            ),
          ),
        ],
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Offline: showing last synced workspace data.'),
        findsOneWidget,
      );
      expect(find.text('Latte'), findsOneWidget);
      expect(find.text('Failed to load menu'), findsNothing);
    },
  );

  testWidgets('MenuPage shows numeric pagination on wide screens', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final items = _menuItems(21);

    await pumpApp(
      tester,
      const MenuPage(),
      overrides: [
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(
            MenuState(
              isLoading: false,
              filteredItems: items,
              allItems: items,
              categories: const [MenuCategory(id: 'cat-1', name: 'Coffee')],
            ),
          ),
        ),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Showing 1-10 entries'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 10'), findsOneWidget);
    expect(find.text('Item 11'), findsNothing);
    expect(find.widgetWithText(FilledButton, '1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '2'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '3'), findsOneWidget);
  });

  testWidgets('MenuPage page taps update the wide-screen table slice', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final items = _menuItems(21);

    await pumpApp(
      tester,
      const MenuPage(),
      overrides: [
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(
            MenuState(
              isLoading: false,
              filteredItems: items,
              allItems: items,
              categories: const [MenuCategory(id: 'cat-1', name: 'Coffee')],
            ),
          ),
        ),
      ],
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '2'));
    await tester.tap(find.widgetWithText(FilledButton, '2'));
    await tester.pumpAndSettle();

    expect(find.text('Showing 11-20 entries'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 11'), findsOneWidget);
    expect(find.text('Item 20'), findsOneWidget);
    expect(find.text('Item 21'), findsNothing);
  });

  testWidgets('MenuPage uses a load-more footer on smaller screens', (
    tester,
  ) async {
    _setNarrowViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final items = _menuItems(21);

    await pumpApp(
      tester,
      const MenuPage(),
      overrides: [
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(
            MenuState(
              isLoading: false,
              filteredItems: items,
              allItems: items,
              categories: const [MenuCategory(id: 'cat-1', name: 'Coffee')],
            ),
          ),
        ),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Load more'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 10'), findsOneWidget);
    expect(find.text('Item 11'), findsNothing);

    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 11'), findsOneWidget);
  });

  testWidgets('MenuPage filter bar and pagination move with page scroll', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    final items = _menuItems(21);

    await pumpApp(
      tester,
      const MenuPage(),
      overrides: [
        menuViewModelProvider.overrideWith(
          () => _StaticMenuViewModel(
            MenuState(
              isLoading: false,
              filteredItems: items,
              allItems: items,
              categories: const [MenuCategory(id: 'cat-1', name: 'Coffee')],
            ),
          ),
        ),
      ],
    );

    await tester.pumpAndSettle();

    final scrollView = find.byKey(const ValueKey('menu-page-scroll-view'));
    final addMenuBefore = tester.getTopLeft(find.text('Add menu')).dy;

    await tester.drag(scrollView, const Offset(0, -220));
    await tester.pumpAndSettle();

    final addMenuAfter = tester.getTopLeft(find.text('Add menu')).dy;
    expect(addMenuAfter, lessThan(addMenuBefore));

    await tester.ensureVisible(find.text('Showing 1-10 entries'));
    await tester.pumpAndSettle();
    final paginationBefore = tester
        .getTopLeft(find.text('Showing 1-10 entries'))
        .dy;

    await tester.drag(scrollView, const Offset(0, 120));
    await tester.pumpAndSettle();

    final paginationAfter = tester
        .getTopLeft(find.text('Showing 1-10 entries'))
        .dy;
    expect(paginationAfter, greaterThan(paginationBefore));
  });
}
