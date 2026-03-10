import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

class CashSessionDto {
  const CashSessionDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.openedByAccountId,
    required this.openedByName,
    required this.openedAt,
    required this.status,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.closedAt,
    required this.closedByAccountId,
    required this.closedByName,
    required this.closeNote,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String openedByAccountId;
  final String openedByName;
  final DateTime? openedAt;
  final String status;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final DateTime? closedAt;
  final String? closedByAccountId;
  final String? closedByName;
  final String? closeNote;

  factory CashSessionDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final raw = json[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    double numOrZero(dynamic value) => (value is num) ? value.toDouble() : 0.0;

    return CashSessionDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      openedByAccountId: json['openedByAccountId']?.toString() ?? '',
      openedByName: json['openedByName']?.toString() ?? '',
      openedAt: parseDate('openedAt'),
      status: CashSessionStatuses.normalize(json['status']?.toString()),
      openingFloatUsd: numOrZero(json['openingFloatUsd']),
      openingFloatKhr: numOrZero(json['openingFloatKhr']),
      closedAt: parseDate('closedAt'),
      closedByAccountId: json['closedByAccountId']?.toString(),
      closedByName: json['closedByName']?.toString(),
      closeNote: json['closeNote']?.toString(),
    );
  }
}
