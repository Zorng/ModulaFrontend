import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

/// Resolves the current active branch assignment for the logged-in user.
///
/// Note: today the "active branch" is derived from the auth session payload.
/// When the app supports explicit branch switching, this provider should be the
/// single source of truth.
final authActiveBranchOverrideProvider = StateProvider<String?>((ref) => null);

final authActiveBranchProvider = Provider<UserBranch?>((ref) {
  final session = ref.watch(loginControllerProvider).session;
  final branches = session?.user.branches ?? const <UserBranch>[];
  if (branches.isEmpty) return null;
  final overrideId = ref.watch(authActiveBranchOverrideProvider);
  if (overrideId != null && overrideId.trim().isNotEmpty) {
    final override = branches.firstWhere(
      (b) => b.id == overrideId || b.branchId == overrideId,
      orElse: () => const UserBranch(
        id: '',
        name: '',
        role: '',
        active: false,
      ),
    );
    if (override.id.isNotEmpty || override.branchId.isNotEmpty) {
      return override;
    }
  }
  return branches.firstWhere(
    (b) => b.active && (b.branchId.isNotEmpty || b.id.isNotEmpty),
    orElse: () => branches.first,
  );
});

/// The resolved active branch id (prefers `branchId`, otherwise falls back to assignment id).
final authActiveBranchIdProvider = Provider<String?>((ref) {
  final branch = ref.watch(authActiveBranchProvider);
  if (branch == null) return null;
  final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
  return id.isNotEmpty ? id : null;
});
