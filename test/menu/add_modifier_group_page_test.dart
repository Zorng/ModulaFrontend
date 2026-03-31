import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class _RecordingMenuViewModel extends MenuViewModel {
  _RecordingMenuViewModel(this._state);

  final MenuState _state;
  ModifierGroup? updatedGroup;
  int updateCalls = 0;

  @override
  MenuState build() => _state;

  @override
  Future<ModifierGroup> updateModifierGroup(ModifierGroup group) async {
    updateCalls += 1;
    updatedGroup = group;
    return group;
  }
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 900);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Future<void> _pumpModifierGroupPage(
  WidgetTester tester, {
  required Widget child,
  required _RecordingMenuViewModel notifier,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/modifier', builder: (_, __) => child),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [menuViewModelProvider.overrideWith(() => notifier)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  router.push('/modifier');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('existing modifier edit on wide screens can add a new option', (
    tester,
  ) async {
    _setWideViewport(tester);
    addTearDown(() => _resetViewport(tester));

    const group = ModifierGroup(
      id: 'group-1',
      name: 'Temperature',
      selectionType: 'multiple',
      pricingBehavior: 'none',
      options: [ModifierOption(id: 'opt-1', name: 'Hot')],
    );

    final notifier = _RecordingMenuViewModel(
      const MenuState(isLoading: false, modifierGroups: [group]),
    );

    await _pumpModifierGroupPage(
      tester,
      child: const AddModifierGroupPage(
        initialGroup: group,
        initialMode: ModifierGroupFormMode.view,
      ),
      notifier: notifier,
    );

    await tester.pumpAndSettle();

    expect(find.text('Add option'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Add option'), findsOneWidget);

    await tester.tap(find.text('Add option'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Iced');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(notifier.updateCalls, 1);
    expect(notifier.updatedGroup, isNotNull);
    expect(notifier.updatedGroup!.options, hasLength(2));
    expect(notifier.updatedGroup!.options.first.id, 'opt-1');
    expect(notifier.updatedGroup!.options.last.id, '');
    expect(notifier.updatedGroup!.options.last.name, 'Iced');
  });
}
