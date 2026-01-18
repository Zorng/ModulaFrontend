# Providers & State Management (Riverpod)

This document defines provider conventions to keep state predictable and prevent circular dependencies.

## Provider type defaults
- Local/UI truth: `NotifierProvider` + `Notifier`
- Backend truth: `AsyncNotifierProvider` + `AsyncNotifier` (expose `AsyncValue<T>`)
- Dependencies (API/repository): `Provider`
- Do not introduce new legacy `StateNotifierProvider`/`StateNotifier`.
- `StateProvider` is allowed only for trivial toggles; otherwise prefer a screen controller.

## Recommended state model: Store + optional screen controller

- **Store (state owner)**:
  - Owns canonical feature state (data cache + mutations).
  - May be shared by multiple screens.
  - Must model `loading/error/data` when backed by backend truth.
- **Screen controller**:
  - Owns only screen-specific state (filters/tabs/pagination cursor, expansion toggles).
  - Should be safe to dispose/recreate without losing canonical data.

## Backend loading style
- Prefer explicit `load()` / `refresh()` methods triggered from UI/controller.
- UI must render loading/error/data states (no freezing).

### Example: Async store with explicit `load()`

This is a pattern to copy for backend-truth state:

```dart
final itemsStoreProvider =
    AsyncNotifierProvider<ItemsStore, List<Item>>(ItemsStore.new);

class ItemsStore extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    // Choose one:
    // 1) return an initial cached value (fast), then refresh via load() from UI, or
    // 2) do a minimal initial fetch if the screen always needs data on entry.
    return const [];
  }

  Future<void> load({required String branchId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(itemsRepositoryProvider);
      return repo.listItems(branchId: branchId);
    });
  }
}
```

UI rendering pattern:

```dart
final items = ref.watch(itemsStoreProvider);
return items.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text(UserErrorMessage.build(context: 'Failed to load', error: e)),
  data: (items) => ItemsList(items: items),
);
```

## `watch` vs `read`
- UI: `watch` for rendering, `read` for event handlers.
- Notifiers: `watch` for stable dependencies; `read` inside actions to reduce circular dependency risk.

## Avoiding circular dependencies (practical rules)

- Do not `ref.watch`/`ref.read` the provider you are currently inside.
- Avoid invalidating or resetting providers during provider construction/build.
  - If you must “hydrate on startup/login”, do it in a UI/controller layer or a post-frame callback (never synchronously during widget build).
- Prefer dependency inversion:
  - Store depends on repository (Provider).
  - Repository depends on API client (Provider).
  - API client depends on Dio (Provider).
