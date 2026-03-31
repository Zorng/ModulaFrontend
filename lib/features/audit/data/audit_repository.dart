import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/audit/data/audit_api.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';

abstract class AuditRepository {
  Future<AuditEventPage> listEvents({
    String? branchId,
    String? actionKey,
    AuditOutcome? outcome,
    int limit = 50,
    int offset = 0,
  });
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final api = ref.read(auditApiProvider);
  return RemoteAuditRepository(api);
});

class RemoteAuditRepository implements AuditRepository {
  const RemoteAuditRepository(this._api);

  final AuditApi _api;

  @override
  Future<AuditEventPage> listEvents({
    String? branchId,
    String? actionKey,
    AuditOutcome? outcome,
    int limit = 50,
    int offset = 0,
  }) async {
    final dto = await _api.listEvents(
      branchId: branchId,
      actionKey: actionKey,
      outcome: outcome,
      limit: limit,
      offset: offset,
    );
    return AuditEventPage(
      items: dto.items.map(_toEvent).toList(growable: false),
      limit: dto.limit,
      offset: dto.offset,
      total: dto.total,
      hasMore: dto.hasMore,
    );
  }

  AuditEvent _toEvent(dynamic dto) {
    return AuditEvent(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      actorAccountId: dto.actorAccountId,
      actorDisplayName: dto.actorDisplayName,
      actionKey: dto.actionKey,
      outcome: AuditOutcome.tryParse(dto.outcome) ?? AuditOutcome.failed,
      reasonCode: dto.reasonCode,
      entityType: dto.entityType,
      entityId: dto.entityId,
      metadata: dto.metadata,
      createdAt:
          _asDateTime(dto.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  DateTime? _asDateTime(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return DateTime.tryParse(value!);
  }
}
