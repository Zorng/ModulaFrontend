import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';

/// Resolves the effective active branch id for branch-scoped features.
final activeBranchContextIdProvider = Provider<String?>((ref) {
  final authBranchId = (ref.watch(authActiveBranchIdProvider) ?? '').trim();
  return authBranchId.isEmpty ? null : authBranchId;
});
