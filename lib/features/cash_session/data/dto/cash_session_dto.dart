class CashSessionDto {
  const CashSessionDto({
    required this.id,
    required this.status,
    required this.openedAt,
    required this.closedAt,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.totalPaidInUsd,
    required this.totalPaidOutUsd,
    required this.openedBy,
    required this.createdBy,
    required this.actorId,
    required this.createdAt,
  });

  final String id;
  final String status;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final double totalPaidInUsd;
  final double totalPaidOutUsd;
  final String? openedBy;
  final String? createdBy;
  final String? actorId;
  final DateTime? createdAt;

  factory CashSessionDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final raw = json[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    double numOrZero(dynamic value) => (value is num) ? value.toDouble() : 0.0;

    return CashSessionDto(
      id: json['id']?.toString() ?? json['sessionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      openedAt:
          parseDate('openedAt') ??
          parseDate('startedAt') ??
          parseDate('createdAt'),
      closedAt: parseDate('closedAt'),
      openingFloatUsd: numOrZero(json['openingFloatUsd']),
      openingFloatKhr: numOrZero(json['openingFloatKhr']),
      totalPaidInUsd: numOrZero(json['totalPaidInUsd'] ?? json['totalPaidIn']),
      totalPaidOutUsd:
          numOrZero(json['totalPaidOutUsd'] ?? json['totalPaidOut']),
      openedBy: json['openedBy']?.toString(),
      createdBy: json['createdBy']?.toString(),
      actorId: json['actorId']?.toString(),
      createdAt: parseDate('createdAt'),
    );
  }
}
