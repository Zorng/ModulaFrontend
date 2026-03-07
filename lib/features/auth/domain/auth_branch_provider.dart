import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

/// Resolves the current active branch assignment for the logged-in user.
///
/// Note: today the "active branch" is derived from the auth session payload.
/// When the app supports explicit branch switching, this provider should be the
/// single source of truth.
final authActiveBranchOverrideProvider =
    NotifierProvider<AuthActiveBranchOverrideNotifier, String?>(
      AuthActiveBranchOverrideNotifier.new,
    );

final authActiveBranchNameOverrideProvider =
    NotifierProvider<AuthActiveBranchNameOverrideNotifier, String?>(
      AuthActiveBranchNameOverrideNotifier.new,
    );

class AuthActiveBranchOverrideNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setOverride(String? branchId) {
    final trimmed = (branchId ?? '').trim();
    state = trimmed.isEmpty ? null : trimmed;
  }

  void clear() => state = null;
}

class AuthActiveBranchNameOverrideNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setName(String? branchName) {
    final trimmed = (branchName ?? '').trim();
    state = trimmed.isEmpty ? null : trimmed;
  }

  void clear() => state = null;
}

final authActiveBranchProvider = Provider<UserBranch?>((ref) {
  final session = ref.watch(loginControllerProvider).session;
  final branches = session?.user.branches ?? const <UserBranch>[];
  final overrideId = ref.watch(authActiveBranchOverrideProvider);
  final overrideName = ref.watch(authActiveBranchNameOverrideProvider);
  if (overrideId != null && overrideId.trim().isNotEmpty) {
    final override = branches.firstWhere(
      (b) => b.id == overrideId || b.branchId == overrideId,
      orElse: () => const UserBranch(id: '', name: '', role: '', active: false),
    );
    if (override.id.isNotEmpty || override.branchId.isNotEmpty) {
      return override;
    }
    return UserBranch(
      id: overrideId,
      branchId: overrideId,
      name: (overrideName ?? '').trim(),
      role: '',
      active: true,
    );
  }
  if (branches.isEmpty) return null;
  final activeBranch = branches.firstWhere(
    (b) => b.active && (b.branchId.isNotEmpty || b.id.isNotEmpty),
    orElse: () => const UserBranch(id: '', name: '', role: '', active: false),
  );
  if (activeBranch.id.isNotEmpty || activeBranch.branchId.isNotEmpty) {
    return activeBranch;
  }
  return null;
});

/// The resolved active branch id (prefers `branchId`, otherwise falls back to assignment id).
final authActiveBranchIdProvider = Provider<String?>((ref) {
  final overrideId = (ref.watch(authActiveBranchOverrideProvider) ?? '').trim();
  if (overrideId.isNotEmpty) return overrideId;
  final branch = ref.watch(authActiveBranchProvider);
  if (branch == null) return null;
  final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
  return id.isNotEmpty ? id : null;
});
