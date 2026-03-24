import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/hydration/context_scoped_runtime_resource.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_client.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_inbox_controller.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_unread_count_controller.dart';

final operationalNotificationRealtimeReconnectDelayProvider =
    Provider<Duration Function(int attempt)>((_) {
      return (attempt) {
        const delays = <Duration>[
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
          Duration(seconds: 16),
          Duration(seconds: 30),
        ];
        final index = attempt - 1;
        if (index <= 0) return delays.first;
        if (index >= delays.length) return delays.last;
        return delays[index];
      };
    });

final operationalNotificationRuntimeResourceProvider =
    Provider<ContextScopedRuntimeResource>((ref) {
      final client = ref.watch(operationalNotificationStreamClientProvider);
      final delayForAttempt = ref.watch(
        operationalNotificationRealtimeReconnectDelayProvider,
      );
      final resource = OperationalNotificationRuntimeResource(
        ref: ref,
        client: client,
        reconnectDelayForAttempt: delayForAttempt,
      );
      ref.onDispose(resource.dispose);
      return resource;
    });

class OperationalNotificationRuntimeResource
    implements ContextScopedRuntimeResource {
  OperationalNotificationRuntimeResource({
    required Ref ref,
    required OperationalNotificationStreamClient client,
    required Duration Function(int attempt) reconnectDelayForAttempt,
  }) : _ref = ref,
       _client = client,
       _reconnectDelayForAttempt = reconnectDelayForAttempt;

  final Ref _ref;
  final OperationalNotificationStreamClient _client;
  final Duration Function(int attempt) _reconnectDelayForAttempt;

  OperationalNotificationStreamConnection? _connection;
  StreamSubscription<OperationalNotificationRealtimeEvent>? _subscription;
  Timer? _reconnectTimer;
  String? _accessToken;
  String? _tenantId;
  String? _branchId;
  int _generation = 0;
  int _reconnectAttempt = 0;
  bool _shouldRefreshInboxOnNextReady = false;

  @override
  bool get requiresTenantContext => false;

  @override
  bool get requiresBranchContext => false;

  @override
  Future<void> onContextCleared() async {
    _generation += 1;
    _accessToken = null;
    _tenantId = null;
    _branchId = null;
    _reconnectAttempt = 0;
    _shouldRefreshInboxOnNextReady = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeActiveConnection();

    if (_ref.exists(operationalNotificationUnreadCountControllerProvider)) {
      _ref
          .read(operationalNotificationUnreadCountControllerProvider.notifier)
          .reset();
    }
    if (_ref.exists(operationalNotificationInboxControllerProvider)) {
      _ref
          .read(operationalNotificationInboxControllerProvider.notifier)
          .reset();
    }
  }

  @override
  Future<void> onContextChanged({
    required String accessToken,
    required String tenantId,
    required String branchId,
  }) async {
    if (!_client.isSupported) return;

    final nextAccessToken = accessToken.trim();
    final nextTenantId = tenantId.trim();
    final nextBranchId = branchId.trim();
    final identityChanged =
        nextAccessToken != (_accessToken ?? '') ||
        nextTenantId != (_tenantId ?? '') ||
        nextBranchId != (_branchId ?? '');

    if (!identityChanged &&
        ((_connection != null) || (_reconnectTimer?.isActive ?? false))) {
      return;
    }

    _generation += 1;
    _accessToken = nextAccessToken;
    _tenantId = nextTenantId;
    _branchId = nextBranchId;
    _reconnectAttempt = 0;
    _shouldRefreshInboxOnNextReady = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeActiveConnection();

    if (_accessToken!.isEmpty) return;

    await _connect(generation: _generation);
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeActiveConnection();
  }

  Future<void> _connect({required int generation}) async {
    final accessToken = _accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    try {
      final connection = await _client.connect(accessToken: accessToken);
      if (generation != _generation) {
        await connection.close();
        return;
      }

      _connection = connection;
      _subscription = connection.events.listen(
        _handleRealtimeEvent,
        onError: (error, stackTrace) {
          AppLog.e(
            'Operational notification stream error',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          );
          _scheduleReconnect(generation: generation);
        },
        onDone: () {
          _scheduleReconnect(generation: generation);
        },
        cancelOnError: false,
      );
      _reconnectAttempt = 0;
    } catch (error, stackTrace) {
      AppLog.e(
        'Failed to connect operational notification stream',
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleReconnect(generation: generation);
    }
  }

  void _handleRealtimeEvent(OperationalNotificationRealtimeEvent event) {
    if (event is OperationalNotificationStreamReadyEvent) {
      if (_ref.exists(operationalNotificationUnreadCountControllerProvider)) {
        _ref
            .read(operationalNotificationUnreadCountControllerProvider.notifier)
            .setUnreadCount(event.unreadCount);
      }
      if (_shouldRefreshInboxOnNextReady &&
          _ref.exists(operationalNotificationInboxControllerProvider)) {
        _shouldRefreshInboxOnNextReady = false;
        unawaited(
          _ref
              .read(operationalNotificationInboxControllerProvider.notifier)
              .refreshIfLoaded(),
        );
      }
      return;
    }

    if (event is OperationalNotificationStreamCreatedEvent) {
      if (_ref.exists(operationalNotificationUnreadCountControllerProvider)) {
        _ref
            .read(operationalNotificationUnreadCountControllerProvider.notifier)
            .setUnreadCount(event.unreadCount);
      }
      if (_ref.exists(operationalNotificationInboxControllerProvider)) {
        _ref
            .read(operationalNotificationInboxControllerProvider.notifier)
            .ingestRealtimeNotification(
              event.notification,
              unreadCount: event.unreadCount,
            );
      }
    }
  }

  void _scheduleReconnect({required int generation}) {
    if (!_client.isSupported) return;
    if (generation != _generation) return;
    if ((_accessToken ?? '').isEmpty) {
      return;
    }

    _subscription?.cancel();
    _subscription = null;
    _connection = null;

    _reconnectTimer?.cancel();
    _reconnectAttempt += 1;
    _shouldRefreshInboxOnNextReady = true;
    final delay = _reconnectDelayForAttempt(_reconnectAttempt);
    _reconnectTimer = Timer(delay, () {
      unawaited(_connect(generation: generation));
    });
  }

  Future<void> _closeActiveConnection() async {
    await _subscription?.cancel();
    _subscription = null;
    final activeConnection = _connection;
    _connection = null;
    if (activeConnection != null) {
      await activeConnection.close();
    }
  }
}
