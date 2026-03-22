enum ReportBranchScope { branch, allBranches }

ReportBranchScope reportBranchScopeFromApi(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'ALL_BRANCHES':
      return ReportBranchScope.allBranches;
    case 'BRANCH':
    default:
      return ReportBranchScope.branch;
  }
}

String reportBranchScopeToApi(ReportBranchScope value) {
  switch (value) {
    case ReportBranchScope.branch:
      return 'BRANCH';
    case ReportBranchScope.allBranches:
      return 'ALL_BRANCHES';
  }
}

class ReportScope {
  const ReportScope({
    required this.tenantId,
    required this.branchScope,
    required this.branchId,
    required this.from,
    required this.to,
    required this.timezone,
    required this.frozenBranchIds,
  });

  final String tenantId;
  final ReportBranchScope branchScope;
  final String? branchId;
  final String from;
  final String to;
  final String timezone;
  final List<String> frozenBranchIds;
}
