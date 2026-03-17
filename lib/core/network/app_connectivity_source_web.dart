import 'dart:async';

import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:web/web.dart' as html;

AppConnectivitySource createPlatformConnectivitySource() {
  return _WebAppConnectivitySource();
}

class _WebAppConnectivitySource implements AppConnectivitySource {
  _WebAppConnectivitySource() {
    _onlineSubscription = html.EventStreamProviders.onlineEvent
        .forTarget(html.window)
        .listen((_) => _emit(AppConnectivityStatus.online));
    _offlineSubscription = html.EventStreamProviders.offlineEvent
        .forTarget(html.window)
        .listen((_) => _emit(AppConnectivityStatus.offline));
  }

  final StreamController<AppConnectivityStatus> _controller =
      StreamController<AppConnectivityStatus>.broadcast();
  late final StreamSubscription<Object?> _onlineSubscription;
  late final StreamSubscription<Object?> _offlineSubscription;

  @override
  AppConnectivityStatus get initialStatus => html.window.navigator.onLine
      ? AppConnectivityStatus.online
      : AppConnectivityStatus.offline;

  @override
  Stream<AppConnectivityStatus> get onStatusChanged => _controller.stream;

  @override
  Future<void> dispose() async {
    await _onlineSubscription.cancel();
    await _offlineSubscription.cancel();
    await _controller.close();
  }

  void _emit(AppConnectivityStatus status) {
    if (_controller.isClosed) return;
    _controller.add(status);
  }
}
