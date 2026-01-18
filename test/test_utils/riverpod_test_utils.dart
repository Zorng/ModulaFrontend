import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Creates a [ProviderContainer] for unit/widget tests and disposes it automatically.
ProviderContainer createTestContainer({
  /// Provider overrides created via `someProvider.overrideWithValue(...)`.
  List<Override> overrides = const [],
  List<ProviderObserver> observers = const [],
}) {
  final container = ProviderContainer(
    overrides: overrides,
    observers: observers,
  );
  addTearDown(container.dispose);
  return container;
}
