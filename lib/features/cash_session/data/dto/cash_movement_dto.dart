import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';

class CashMovementDto {
  const CashMovementDto({
    required this.id,
    required this.sessionId,
    required this.tenantId,
    required this.branchId,
    required this.movementType,
    required this.amountUsd,
    required this.amountKhr,
    required this.reason,
    required this.sourceRefType,
    required this.sourceRefId,
    required this.recordedByAccountId,
    required this.occurredAt,
  });

  final String id;
  final String sessionId;
  final String tenantId;
  final String branchId;
  final String movementType;
  final double amountUsd;
  final double amountKhr;
  final String? reason;
  final String sourceRefType;
  final String? sourceRefId;
  final String recordedByAccountId;
  final DateTime? occurredAt;

  factory CashMovementDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final raw = json[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    double numOrZero(dynamic value) => (value is num) ? value.toDouble() : 0.0;

    return CashMovementDto(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      movementType: CashMovementTypes.normalize(json['movementType']?.toString()),
      amountUsd: numOrZero(json['amountUsd']),
      amountKhr: numOrZero(json['amountKhr']),
      reason: json['reason']?.toString(),
      sourceRefType: json['sourceRefType']?.toString() ?? 'MANUAL',
      sourceRefId: json['sourceRefId']?.toString(),
      recordedByAccountId: json['recordedByAccountId']?.toString() ?? '',
      occurredAt: parseDate('occurredAt'),
    );
  }
}
