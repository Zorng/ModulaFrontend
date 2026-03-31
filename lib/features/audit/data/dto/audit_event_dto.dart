import 'package:modular_pos/core/network/api_contract.dart';

class AuditEventDto {
  const AuditEventDto({
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
    this.createdAt,
  });

  factory AuditEventDto.fromJson(Map<String, dynamic> json) {
    return AuditEventDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: _asNullableString(json['branchId']),
      actorAccountId: _asNullableString(json['actorAccountId']),
      actorDisplayName: _asNullableString(json['actorDisplayName']),
      actionKey: json['actionKey']?.toString() ?? '',
      outcome: json['outcome']?.toString() ?? '',
      reasonCode: _asNullableString(json['reasonCode']),
      entityType: _asNullableString(json['entityType']),
      entityId: _asNullableString(json['entityId']),
      metadata: ApiContract.asJsonMap(json['metadata']),
      createdAt: json['createdAt']?.toString(),
    );
  }

  final String id;
  final String tenantId;
  final String? branchId;
  final String? actorAccountId;
  final String? actorDisplayName;
  final String actionKey;
  final String outcome;
  final String? reasonCode;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final String? createdAt;
}

class AuditEventPageDto {
  const AuditEventPageDto({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  factory AuditEventPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (entry) => AuditEventDto.fromJson(ApiContract.asJsonMap(entry)),
              )
              .toList(growable: false)
        : const <AuditEventDto>[];

    return AuditEventPageDto(
      items: items,
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
      total: _asInt(json['total']),
      hasMore: json['hasMore'] == true,
    );
  }

  final List<AuditEventDto> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
}

String? _asNullableString(dynamic value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
