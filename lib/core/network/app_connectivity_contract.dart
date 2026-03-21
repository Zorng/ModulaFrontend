import 'dart:async';

enum AppConnectivityStatus { online, offline }

abstract class AppConnectivitySource {
  AppConnectivityStatus get initialStatus;

  Stream<AppConnectivityStatus> get onStatusChanged;

  FutureOr<void> dispose() {}
}
