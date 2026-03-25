import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';

Map<String, String> reportScopeQueryToRouteParameters(ReportScopeQuery scope) {
  final branchId = scope.branchScope == ReportBranchScope.branch
      ? _normalized(scope.branchId)
      : null;

  return {
    'window': reportTimeWindowToApi(scope.window),
    'branchScope': reportBranchScopeToApi(scope.branchScope),
    if (scope.from case final from?) 'from': from,
    if (scope.to case final to?) 'to': to,
    if (branchId != null) 'branchId': branchId,
  };
}

ReportScopeQuery? reportScopeQueryFromRouteParameters(
  Map<String, String> queryParameters,
) {
  if (queryParameters.isEmpty) {
    return null;
  }

  final branchScope = reportBranchScopeFromApi(queryParameters['branchScope']);
  final branchId = _normalized(queryParameters['branchId']);
  if (branchScope == ReportBranchScope.branch && branchId == null) {
    return null;
  }

  return ReportScopeQuery(
    window: reportTimeWindowFromApi(queryParameters['window']),
    from: _normalized(queryParameters['from']),
    to: _normalized(queryParameters['to']),
    branchScope: branchScope,
    branchId: branchScope == ReportBranchScope.branch ? branchId : null,
  );
}

String? _normalized(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
