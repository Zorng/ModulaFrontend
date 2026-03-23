import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_client_stub.dart'
    if (dart.library.js_interop) 'package:modular_pos/features/notification/data/operational_notification_stream_client_web.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';

final operationalNotificationStreamClientProvider =
    Provider<OperationalNotificationStreamClient>((ref) {
      return createPlatformOperationalNotificationStreamClient(
        baseUrl: AppEnv.apiBaseUrl,
        prefix: AppEnv.notificationApiPrefix,
      );
    });
