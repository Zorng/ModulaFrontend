import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';

OperationalNotificationStreamClient
createPlatformOperationalNotificationStreamClient({
  required String baseUrl,
  required String prefix,
}) {
  return const _StubOperationalNotificationStreamClient();
}

class _StubOperationalNotificationStreamClient
    implements OperationalNotificationStreamClient {
  const _StubOperationalNotificationStreamClient();

  @override
  bool get isSupported => false;

  @override
  Future<OperationalNotificationStreamConnection> connect({
    required String accessToken,
  }) async {
    return const _StubOperationalNotificationStreamConnection();
  }
}

class _StubOperationalNotificationStreamConnection
    implements OperationalNotificationStreamConnection {
  const _StubOperationalNotificationStreamConnection();

  @override
  Stream<OperationalNotificationRealtimeEvent> get events =>
      const Stream<OperationalNotificationRealtimeEvent>.empty();

  @override
  Future<void> close() async {}
}
