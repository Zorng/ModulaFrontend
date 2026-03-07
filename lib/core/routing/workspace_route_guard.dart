import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';

const String branchSelectionReasonQueryParam = 'reason';
const String branchContextRequiredReasonCode = 'branch_context_required';
const String branchContextRequiredUserMessage =
    'Branch context is missing. Please select a branch to continue.';
const String branchContinueQueryParam = 'continue';

bool isPathInGroup(String path, String root) {
  return path == root || path.startsWith('$root/');
}

String? sanitizeContinuePath(String? path) {
  final normalized = (path ?? '').trim();
  if (normalized.isEmpty) return null;
  if (!normalized.startsWith('/')) return null;
  if (normalized.startsWith('//')) return null;
  if (normalized.contains('://')) return null;
  return normalized;
}

String? readContinuePath(Uri uri) {
  return sanitizeContinuePath(uri.queryParameters[branchContinueQueryParam]);
}

String buildBranchSelectionRedirect({
  String? reasonCode,
  String? continuePath,
}) {
  return _buildRedirect(
    basePath: AppRoute.branchSelection.path,
    reasonCode: reasonCode,
    continuePath: continuePath,
  );
}

String buildBranchesRedirect({
  String? reasonCode,
  String? continuePath,
}) {
  return _buildRedirect(
    basePath: AppRoute.branch.path,
    reasonCode: reasonCode,
    continuePath: continuePath,
  );
}

String buildBranchScopedRedirectForRole({
  required AuthRole role,
  required String continuePath,
  String? reasonCode,
}) {
  final normalizedContinuePath =
      sanitizeContinuePath(continuePath) ?? AppRoute.cashSession.path;
  if (role == AuthRole.owner || role == AuthRole.admin) {
    return buildBranchesRedirect(
      reasonCode: reasonCode,
      continuePath: normalizedContinuePath,
    );
  }
  return buildBranchSelectionRedirect(
    reasonCode: reasonCode,
    continuePath: normalizedContinuePath,
  );
}

String _buildRedirect({
  required String basePath,
  String? reasonCode,
  String? continuePath,
}) {
  final queryParameters = <String, String>{};
  final normalizedReason = (reasonCode ?? '').trim();
  final normalizedContinuePath = sanitizeContinuePath(continuePath);
  if (normalizedReason.isNotEmpty) {
    queryParameters[branchSelectionReasonQueryParam] = normalizedReason;
  }
  if (normalizedContinuePath != null) {
    queryParameters[branchContinueQueryParam] = normalizedContinuePath;
  }
  if (queryParameters.isEmpty) return basePath;
  return Uri(path: basePath, queryParameters: queryParameters).toString();
}
