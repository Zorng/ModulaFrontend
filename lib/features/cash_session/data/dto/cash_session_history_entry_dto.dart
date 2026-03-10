import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

class CashSessionHistoryEntryDto {
  const CashSessionHistoryEntryDto({
    required this.id,
    required this.status,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
  });

  final String id;
  final String status;
  final String openedByName;
  final DateTime? openedAt;
  final DateTime? closedAt;

  factory CashSessionHistoryEntryDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final raw = json[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return CashSessionHistoryEntryDto(
      id: json['id']?.toString() ?? '',
      status: CashSessionStatuses.normalize(json['status']?.toString()),
      openedByName: json['openedByName']?.toString() ?? '',
      openedAt: parseDate('openedAt'),
      closedAt: parseDate('closedAt'),
    );
  }
}
