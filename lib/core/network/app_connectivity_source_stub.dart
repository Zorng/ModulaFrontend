import 'package:modular_pos/core/network/app_connectivity_contract.dart';

AppConnectivitySource createPlatformConnectivitySource() {
  return _StubAppConnectivitySource();
}

class _StubAppConnectivitySource implements AppConnectivitySource {
  @override
  AppConnectivityStatus get initialStatus => AppConnectivityStatus.online;

  @override
  Stream<AppConnectivityStatus> get onStatusChanged =>
      const Stream<AppConnectivityStatus>.empty();

  @override
  void dispose() {}
}
