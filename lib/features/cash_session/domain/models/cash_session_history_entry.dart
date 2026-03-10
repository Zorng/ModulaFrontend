import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

class CashSessionHistoryEntry {
  const CashSessionHistoryEntry({
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

  bool get isClosed => CashSessionStatuses.isClosed(status);
}
