enum WorkspaceScope { global, branch }

enum WorkspaceMode { management, pos }

class WorkspaceContext {
  const WorkspaceContext({
    required this.scope,
    required this.mode,
    required this.activeBranchId,
  });

  final WorkspaceScope scope;
  final WorkspaceMode mode;
  final String? activeBranchId;

  bool get isGlobal => scope == WorkspaceScope.global;
  bool get isBranch => scope == WorkspaceScope.branch;
  bool get isManagement => mode == WorkspaceMode.management;
  bool get isPos => mode == WorkspaceMode.pos;

  WorkspaceContext copyWith({
    WorkspaceScope? scope,
    WorkspaceMode? mode,
    String? activeBranchId,
  }) {
    return WorkspaceContext(
      scope: scope ?? this.scope,
      mode: mode ?? this.mode,
      activeBranchId: activeBranchId ?? this.activeBranchId,
    );
  }

  static const WorkspaceContext globalManagement = WorkspaceContext(
    scope: WorkspaceScope.global,
    mode: WorkspaceMode.management,
    activeBranchId: null,
  );

  static WorkspaceContext branchManagement({required String activeBranchId}) {
    return WorkspaceContext(
      scope: WorkspaceScope.branch,
      mode: WorkspaceMode.management,
      activeBranchId: activeBranchId.trim(),
    );
  }

  static WorkspaceContext branchPos({required String activeBranchId}) {
    return WorkspaceContext(
      scope: WorkspaceScope.branch,
      mode: WorkspaceMode.pos,
      activeBranchId: activeBranchId.trim(),
    );
  }
}
