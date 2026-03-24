import 'dart:async';

import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

abstract class OperationalNotificationStreamClient {
  bool get isSupported;

  Future<OperationalNotificationStreamConnection> connect({
    required String accessToken,
  });
}

abstract class OperationalNotificationStreamConnection {
  Stream<OperationalNotificationRealtimeEvent> get events;

  Future<void> close();
}

sealed class OperationalNotificationRealtimeEvent {
  const OperationalNotificationRealtimeEvent();
}

class OperationalNotificationStreamReadyEvent
    extends OperationalNotificationRealtimeEvent {
  const OperationalNotificationStreamReadyEvent({
    required this.unreadCount,
    this.serverTime,
  });

  final int unreadCount;
  final DateTime? serverTime;
}

class OperationalNotificationStreamCreatedEvent
    extends OperationalNotificationRealtimeEvent {
  const OperationalNotificationStreamCreatedEvent({
    required this.notification,
    required this.unreadCount,
  });

  final OperationalNotificationItem notification;
  final int unreadCount;
}
