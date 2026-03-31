enum AuditOutcome {
  success('SUCCESS'),
  rejected('REJECTED'),
  failed('FAILED');

  const AuditOutcome(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
    AuditOutcome.success => 'Success',
    AuditOutcome.rejected => 'Rejected',
    AuditOutcome.failed => 'Failed',
  };

  static AuditOutcome? tryParse(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final outcome in AuditOutcome.values) {
      if (outcome.wireValue == normalized) return outcome;
    }
    return null;
  }
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.tenantId,
    this.branchId,
    this.actorAccountId,
    this.actorDisplayName,
    required this.actionKey,
    required this.outcome,
    this.reasonCode,
    this.entityType,
    this.entityId,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String? branchId;
  final String? actorAccountId;
  final String? actorDisplayName;
  final String actionKey;
  final AuditOutcome outcome;
  final String? reasonCode;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}

class AuditEventPage {
  const AuditEventPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final List<AuditEvent> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
}

class AuditEventQuery {
  const AuditEventQuery({
    this.branchId,
    this.actionKey,
    this.outcome,
    this.limit = 50,
    this.offset = 0,
  });

  final String? branchId;
  final String? actionKey;
  final AuditOutcome? outcome;
  final int limit;
  final int offset;

  AuditEventQuery copyWith({
    Object? branchId = _unset,
    Object? actionKey = _unset,
    Object? outcome = _unset,
    int? limit,
    int? offset,
  }) {
    return AuditEventQuery(
      branchId: identical(branchId, _unset)
          ? this.branchId
          : branchId as String?,
      actionKey: identical(actionKey, _unset)
          ? this.actionKey
          : actionKey as String?,
      outcome: identical(outcome, _unset)
          ? this.outcome
          : outcome as AuditOutcome?,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  static const Object _unset = Object();
}
