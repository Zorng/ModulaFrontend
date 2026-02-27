import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';

const String branchSelectionReasonQueryParam = 'reason';
const String branchContextRequiredReasonCode = 'branch_context_required';
const String branchContextRequiredUserMessage =
    'Branch context is missing. Please select a branch to continue.';

bool isPathInGroup(String path, String root) {
  return path == root || path.startsWith('$root/');
}

String buildBranchSelectionRedirect({String? reasonCode}) {
  final normalizedReason = (reasonCode ?? '').trim();
  if (normalizedReason.isEmpty) return AppRoute.branchSelection.path;
  return Uri(
    path: AppRoute.branchSelection.path,
    queryParameters: <String, String>{
      branchSelectionReasonQueryParam: normalizedReason,
    },
  ).toString();
}

String? guardBranchWorkspaceAccess({
  required WorkspaceContext? workspaceContext,
  required String? activeBranchId,
}) {
  if (workspaceContext?.scope != WorkspaceScope.branch) {
    return '/404';
  }
  final normalizedBranchId = (activeBranchId ?? '').trim();
  if (normalizedBranchId.isEmpty) {
    return buildBranchSelectionRedirect(
      reasonCode: branchContextRequiredReasonCode,
    );
  }
  return null;
}
