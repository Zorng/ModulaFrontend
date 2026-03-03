import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';

final workspaceContextProvider =
    NotifierProvider<WorkspaceContextNotifier, WorkspaceContext?>(
      WorkspaceContextNotifier.new,
    );

class WorkspaceContextNotifier extends Notifier<WorkspaceContext?> {
  @override
  WorkspaceContext? build() => null;

  void setGlobalManagement() {
    state = WorkspaceContext.globalManagement;
  }

  void setBranchManagement({required String activeBranchId}) {
    state = WorkspaceContext.branchManagement(activeBranchId: activeBranchId);
  }

  void setBranchPos({required String activeBranchId}) {
    state = WorkspaceContext.branchPos(activeBranchId: activeBranchId);
  }

  void setFromBranchSelection({
    required bool isAdminOrOwner,
    required String activeBranchId,
  }) {
    if (isAdminOrOwner) {
      setBranchManagement(activeBranchId: activeBranchId);
      return;
    }
    setBranchPos(activeBranchId: activeBranchId);
  }

  void clear() {
    state = null;
  }
}
