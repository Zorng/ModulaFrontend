import 'package:modular_pos/core/network/api_contract.dart';

class OperationalNotificationItemDto {
  const OperationalNotificationItemDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.type,
    required this.subjectType,
    required this.subjectId,
    required this.title,
    required this.body,
    required this.dedupeKey,
    required this.createdAt,
    required this.isRead,
    this.payload,
    this.readAt,
  });

  factory OperationalNotificationItemDto.fromJson(Map<String, dynamic> json) {
    return OperationalNotificationItemDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      subjectType: json['subjectType']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      dedupeKey: json['dedupeKey']?.toString() ?? '',
      payload: _payloadAsJsonMap(json['payload']),
      createdAt: json['createdAt']?.toString(),
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
    );
  }

  final String id;
  final String tenantId;
  final String branchId;
  final String type;
  final String subjectType;
  final String subjectId;
  final String title;
  final String body;
  final String dedupeKey;
  final Map<String, dynamic>? payload;
  final String? createdAt;
  final bool isRead;
  final String? readAt;

  static Map<String, dynamic>? _payloadAsJsonMap(dynamic value) {
    final map = ApiContract.asJsonMap(value);
    if (map.isEmpty) return null;
    return map;
  }
}

class OperationalNotificationInboxPageDto {
  const OperationalNotificationInboxPageDto({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  factory OperationalNotificationInboxPageDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (entry) => OperationalNotificationItemDto.fromJson(
                  ApiContract.asJsonMap(entry),
                ),
              )
              .toList(growable: false)
        : const <OperationalNotificationItemDto>[];
    return OperationalNotificationInboxPageDto(
      items: items,
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
      total: _asInt(json['total']),
      hasMore: json['hasMore'] == true,
    );
  }

  final List<OperationalNotificationItemDto> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
}

class OperationalNotificationUnreadCountDto {
  const OperationalNotificationUnreadCountDto({required this.unreadCount});

  factory OperationalNotificationUnreadCountDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalNotificationUnreadCountDto(
      unreadCount: _asInt(json['unreadCount']),
    );
  }

  final int unreadCount;
}

class OperationalNotificationReadResultDto {
  const OperationalNotificationReadResultDto({
    required this.notificationId,
    required this.isRead,
    this.readAt,
  });

  factory OperationalNotificationReadResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalNotificationReadResultDto(
      notificationId: json['notificationId']?.toString() ?? '',
      isRead: json['isRead'] == true,
      readAt: json['readAt']?.toString(),
    );
  }

  final String notificationId;
  final bool isRead;
  final String? readAt;
}

class OperationalNotificationMarkAllReadResultDto {
  const OperationalNotificationMarkAllReadResultDto({
    required this.updatedCount,
  });

  factory OperationalNotificationMarkAllReadResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return OperationalNotificationMarkAllReadResultDto(
      updatedCount: _asInt(json['updatedCount']),
    );
  }

  final int updatedCount;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
