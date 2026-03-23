import 'dart:convert';

import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/notification/data/dto/operational_notification_dto.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

class OperationalNotificationSseParser {
  String _buffer = '';

  List<OperationalNotificationRealtimeEvent> addChunk(String chunk) {
    _buffer += _normalizeNewlines(chunk);
    return _drainCompletedEvents();
  }

  List<OperationalNotificationRealtimeEvent> close() {
    if (_buffer.trim().isEmpty) {
      _buffer = '';
      return const <OperationalNotificationRealtimeEvent>[];
    }
    _buffer = '$_buffer\n\n';
    return _drainCompletedEvents();
  }

  List<OperationalNotificationRealtimeEvent> _drainCompletedEvents() {
    final events = <OperationalNotificationRealtimeEvent>[];
    while (true) {
      final delimiterIndex = _buffer.indexOf('\n\n');
      if (delimiterIndex == -1) break;

      final block = _buffer.substring(0, delimiterIndex);
      _buffer = _buffer.substring(delimiterIndex + 2);

      final event = _parseEventBlock(block);
      if (event != null) {
        events.add(event);
      }
    }
    return events;
  }

  OperationalNotificationRealtimeEvent? _parseEventBlock(String block) {
    var eventName = '';
    final dataLines = <String>[];

    for (final rawLine in block.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty || line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
        continue;
      }
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    if (dataLines.isEmpty) return null;
    final payload = ApiContract.asJsonMap(jsonDecode(dataLines.join('\n')));

    switch (eventName) {
      case 'ready':
        return OperationalNotificationStreamReadyEvent(
          unreadCount: _asInt(payload['unreadCount']),
          serverTime: _asDateTime(payload['serverTime']?.toString()),
        );
      case 'notification.created':
        return OperationalNotificationStreamCreatedEvent(
          notification: _toCreatedNotification(payload),
          unreadCount: _asInt(payload['unreadCount']),
        );
      default:
        return null;
    }
  }

  OperationalNotificationItem _toCreatedNotification(
    Map<String, dynamic> json,
  ) {
    final dto = OperationalNotificationItemDto.fromJson({
      'id': json['notificationId'],
      'tenantId': json['tenantId'],
      'branchId': json['branchId'],
      'type': json['notificationType'],
      'subjectType': json['subjectType'],
      'subjectId': json['subjectId'],
      'title': json['title'],
      'body': json['body'],
      'dedupeKey': '',
      'payload': json['payload'],
      'createdAt': json['createdAt'],
      'isRead': false,
      'readAt': null,
    });
    return OperationalNotificationItem(
      id: dto.id,
      tenantId: dto.tenantId,
      branchId: dto.branchId,
      type: OperationalNotificationTypes.normalize(dto.type),
      subjectType: OperationalNotificationSubjectTypes.normalize(
        dto.subjectType,
      ),
      subjectId: dto.subjectId,
      title: dto.title,
      body: dto.body,
      dedupeKey: dto.dedupeKey,
      payload: dto.payload,
      createdAt:
          _asDateTime(dto.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isRead: false,
      readAt: null,
    );
  }

  String _normalizeNewlines(String input) {
    return input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _asDateTime(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return DateTime.tryParse(value!);
  }
}
