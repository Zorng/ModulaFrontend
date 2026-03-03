import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';

/// Resolves the effective active branch id for workspace-scoped features.
///
/// Priority:
/// 1) branch id from workspace context (when scope is branch)
/// 2) auth-derived active branch id fallback
final activeBranchContextIdProvider = Provider<String?>((ref) {
  final workspaceContext = ref.watch(workspaceContextProvider);
  if (workspaceContext != null) {
    if (workspaceContext.scope == WorkspaceScope.global) return null;
    final workspaceBranchId = (workspaceContext.activeBranchId ?? '').trim();
    return workspaceBranchId.isEmpty ? null : workspaceBranchId;
  }

  final authBranchId = (ref.watch(authActiveBranchIdProvider) ?? '').trim();
  return authBranchId.isEmpty ? null : authBranchId;
});
