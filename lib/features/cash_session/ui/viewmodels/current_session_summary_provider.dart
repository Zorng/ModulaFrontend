import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/x_report.dart';

final currentSessionSummaryProvider = FutureProvider<XReportDetail?>((
  ref,
) async {
  final branchId = ref.watch(authActiveBranchIdProvider);
  final sessionState = ref.watch(cashSessionViewModelProvider);
  final sessionId = sessionState.sessionId;

  if (branchId == null ||
      branchId.isEmpty ||
      sessionId == null ||
      sessionId.isEmpty) {
    return null;
  }
  if (sessionState.sessionStatus != SessionStatus.open ||
      !sessionState.isOwnedByCurrentUser) {
    return null;
  }

  final repo = ref.read(reportingRepositoryProvider);
  return repo.fetchXReportDetail(sessionId: sessionId, branchId: branchId);
});
