import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branch/data/branch_providers.dart';
import 'package:modular_pos/features/branch/domain/models/branch.dart';

/// Branch store - manages branch list state
final branchStoreProvider =
    AsyncNotifierProvider<BranchStore, List<Branch>>(BranchStore.new);

class BranchStore extends AsyncNotifier<List<Branch>> {
  @override
  Future<List<Branch>> build() async {
    // Return empty initial state; UI triggers explicit load
    return const [];
  }

  /// Load branches from backend
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(branchRepositoryProvider);
      return repo.listBranches();
    });
  }

  /// Refresh branches
  Future<void> refresh() => load();

  /// Get a single branch from the list
  Branch? getBranchById(String branchId) {
    final branches = state.value;
    if (branches == null) return null;
    return branches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => throw Exception('Branch not found'),
    );
  }
}
